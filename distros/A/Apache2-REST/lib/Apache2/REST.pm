package Apache2::REST;

use warnings;
use strict;

use APR::Table ();

use Apache2::Request ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Response ();
use Apache2::RequestUtil ();
use Apache2::Log;

use Apache2::REST::Handler ;
use Apache2::REST::Response ;
use Apache2::REST::Request ;

use Apache2::REST::Conf ;

use Data::Dumper ;

our $VERSION = '0.07';

=head1 NAME

Apache2::REST - Micro framework for REST API implementation under apache2/mod_perl2/apreq2

=head1 VERSION

Version 0.07

=head1 QUICK TUTORIAL

=head2 1. Implement a Apache2::REST::Handler

This module will handle the root resource of your REST API.

   package MyApp::REST::API ;
   use warnings ;
   use strict ;

   # Implement the GET HTTP method.
   sub GET{
       my ($self, $request, $response) = @_ ;
       $response->data()->{'api_mess'} = 'Hello, this is MyApp REST API' ;
       return Apache2::Const::HTTP_OK ;
   }
   # Authorize the GET method.
   sub isAuth{
      my ($self, $method, $req) = @ _; 
      return $method eq 'GET';
   }
   1 ;

=head2 2. Configure apache2

Apache2::REST is a mod_perl2 handler.

In your apache configuration:

   # Make sure you
   LoadModule apreq_module modules/mod_apreq2.so
   LoadModule perl_module modules/mod_perl.so

   # Load Apache2::REST
   PerlModule Apache2::REST 
   # Let Apache2::REST handle the /
   # and set the root handler of the API
   <Location />
      SetHandler perl-script
      PerlSetVar Apache2RESTHandlerRootClass "MyApp::REST::API"
      PerlResponseHandler  Apache2::REST
   </Location>

See L<Apache2::REST::Handler> for  about how to implement a handler.

Then access C<http://yourhost/>. You should see your greeting message from your MyApp::REST::API handler.

See L<Apache2::REST::Overview> for more details about how it works.

=head1 PARTICIPATE

See the Google project page for wiki and collaborative tools: L<http://code.google.com/p/apache2rest/>

=head1 CONFIGURATION

This mod_perl2 handler supports the following configurations (Via PerlSetVar):

=head2  Supported variables

=head3 Apache2RESTAPIBase

The base of the API application. If ommitted, C</> is assumed. Use this to implement your API
as a sub directory of your server.

Example:

    <Location /api/>
      ...
      PerlSetVar Apache2RESTAPIBase "/api/" ;
    </Location>


=head3 Apache2RESTErrorOutput

Defines where to output the error in case of API error.

The default outputs the error in the response message and in
the main apache2 error log.

Valid values are:
    'both' (default)
    'response' (outputs error only in response)
    'server'   (outputs error only in server logs. The response contains
                an error reference for easy retrieval in the error log file)


=head3 Apache2RESTHandlerRootClass

root class of your API implementation. If ommitted, this module will feature the demo implementation
Accessible at C<http://localhost/test/> (providing you installed this at the root of the server)

Example:

    PerlSetVar Apache2RESTHandlerRootClass "MyApp::REST::API"

=head3 Apache2RESTParamEncoding

Encoding of the parameters sent to this API. Default is UTF-8.
Must be a value compatible with L<Encode>

Example:

    PerlSetVar Apache2RESTParamEncoding "UTF-8"

=head3 Apache2RESTAppAuth

Specifies the module to use for application authentication.
See L<Apache2::REST::AppAuth> for API.

Example:

    PerlSetVar Apache2RESTAppAuth "MyApp::REST::AppAuth"

=head3 Apache2RESTWriterSelectMethod

Use this to specify the writer selection method. If not specifid the writer is selected using the C<fmt> parameter.

Valid values are:

    param (the default) - With this method, the writer is selected from the fmt parameter. For instance '?fmt=json'
    extension - With this method, the writer is selected from the url extension. For instance : '/test.json'
    header - With this method, the writer is selected from the MIME type given in the Accept HTTP header
             This MIME type should match one of the writer's mimeType.

Example:
    
    When using 'param' (default) ask for json format like this: http://localhost/test/?fmt=json
    When using 'extension' : http://localhost/test.json

=head3 Apache2RESTWriterDefault

Sets the default writer. If ommitted, the default is C<xml>. Available writers are C<xml>, C<json>, C<yaml>, C<perl>, C<bin>

=head2 command line REST client

This module comes with a commandline REST client to test your API:

   $ restclient
   usage: restclient -r <resource URL> [ -m <http method> ] [ -p <http paramstring> ] [ -h <http headers(param syntax)> ]

It is written as a thin layer on top of L<REST::Client>

=head2 Apache2RESTWriterRegistry

Use this to register your own Writer Classes.

For instance, you want to register your writer under the format name myfmt:

   PerlAddVar Apache2RESTWriterRegistry 'myfmt'
   PerlAddVar Apache2RESTWriterRegistry 'MyApp::REST::Writer::mywriter"

C<MyApp::REST::Writer::mywriter> Must be a subclass of C<Apache2::REST::Writer>.

You can now use your new registered writer by using fmt=myfmt.

=cut


# Private
my $_wtClasses = {
    'xml'  => 'Apache2::REST::Writer::xml' ,
    'json' => 'Apache2::REST::Writer::json' ,
    'yaml' => 'Apache2::REST::Writer::yaml' ,
    'perl' => 'Apache2::REST::Writer::perl' ,
    'bin'  => 'Apache2::REST::Writer::bin' ,
    'xml_stream'     => 'Apache2::REST::Writer::xml_stream',
    'yaml_stream'    => 'Apache2::REST::Writer::yaml_stream' ,
    'yaml_multipart' => 'Apache2::REST::Writer::yaml_multipart' ,
};
my $_MIME2wtClass = {};
my $_isInit = 0 ;

sub doInit{
    my $r = shift ;
    my $req = shift ;

    ## Initialize Apache2RESTWriterRegistry
    my %wt = $r->dir_config->get('Apache2RESTWriterRegistry');
    unless( keys %wt ){
        %wt = () ;
    }
    foreach my $key ( keys %wt ){
        $_wtClasses->{$key} = $wt{$key} ;
    }

    ## Register all the mimetypes
    my $dummyResp = Apache2::REST::Response->new() ;
    foreach my $key ( keys %$_wtClasses ){
        my $class = $_wtClasses->{$key} ;
        eval "require $class;" ;
        if ( $@ ){
            warn "Cannot load $class: $@\n";
            next ;
        }
	warn "Loaded writer class $class\n";
        my $dummyWriter = $class->new();
        my $mimeType = $dummyWriter->mimeType($dummyResp);
        $_MIME2wtClass->{$dummyWriter->mimeType($dummyResp)} = $key ;
    }
}


sub handler{
    my $r = shift ;
    my $req = Apache2::REST::Request->new($r);
    my $paramEncoding = $r->dir_config('Apache2RESTParamEncoding') || '';
    if ( $paramEncoding  ){
        $req->paramEncoding($paramEncoding) ;
    }

    unless( $_isInit ){
        doInit($r, $req) ;
        $_isInit = 1 ;
    }

    ## Response object
    my $resp = Apache2::REST::Response->new() ;
    my $retCode = undef ;

    my $uri = $req->uri() ;
    if ( my $base = $r->dir_config('Apache2RESTAPIBase')){
        $uri =~ s/^\Q$base\E// ;
    }

    ## Get the requested format
    my $wtMethod = $r->dir_config('Apache2RESTWriterSelectMethod') || 'param' ;
    my $format = '' ;
    if ( $wtMethod eq 'param' ){ $format = $req->param('fmt') || '' ; }
    if ( $wtMethod eq 'extension'){ ( $format ) = ( $uri =~ /\.(\w+)$/ ) ; $uri =~ s/\.\w+$// ;  $format ||= '' ;}
    if ( $wtMethod eq 'header' ){ $format = $_MIME2wtClass->{$r->headers_in->{'Accept'}}; }


    # Let Apache2::REST::Request know about requested_format
    $req->requestedFormat($format) ;


    ## Application level authorisation part
    my $appAuth = $r->dir_config('Apache2RESTAppAuth') || '' ;
    if ( $appAuth ){
        eval "require $appAuth;";
        if ( $@ ){
            die "Cannot find AppAuth class $appAuth (from conf Apache2RESTAppAuth)\n" ;
        }
        my $appAuth = $appAuth->new() ;
        $appAuth->init($req) ;
        ## The header
        ## Ok the header is there
        ## Authorize will set message and return true (authorize) or false.
        my $isAuth = $appAuth->authorize($req , $resp ) ;
        unless( $isAuth ){
            $retCode = Apache2::Const::HTTP_UNAUTHORIZED ;
            goto output ;
        }
    }


    my $handlerRootClass = $r->dir_config('Apache2RESTHandlerRootClass') || 'Apache2::REST::Handler' ;

    eval "require $handlerRootClass;";
    if ( $@ ){
        die "Cannot find root class $handlerRootClass (from conf Apache2RESTHandlerRootClass): $@\n" ;
    }

    my $topHandler = $handlerRootClass->new() ;
    my $conf = Apache2::REST::Conf->new() ;
    $conf->Apache2RESTErrorOutput($r->dir_config('Apache2RESTErrorOutput') || 'both' );
    $topHandler->conf($conf);

    my @stack = split('\/+' , $uri);
    # Protect against empty fragments.
    @stack = grep { length($_)>0 } @stack ;



    $retCode = $topHandler->handle(\@stack , $req , $resp ) ;

  output:
    ## Load the writer for the given format
    my $defaultWriter = $r->dir_config('Apache2RESTWriterDefault') || 'xml' ;
    my $wClass = $_wtClasses->{$req->requestedFormat()} || $_wtClasses->{$defaultWriter}  ;
    if ($resp->stream()){
        $wClass .= '_stream';
    } elsif ($resp->multipart_stream()) {
        $wClass .= '_multipart';
    }
    eval "require $wClass;" ;
    if ( $@ ){
        warn "Cannot load $wClass:$@\n" ;
        ## Silently fail to default writer
        require Apache2::REST::Writer::xml ;
        $wClass = 'Apache2::REST::Writer::xml' ;
    }
    my $writer = $wClass->new() ;

    if($writer->can('handleModPerlResponse')){
        ## Use that instead of the legacy code below. (See TODO)
        return $writer->handleModPerlResponse($r,$resp,$retCode);
    }

    ## TODO: Refactor that so it goes in a writer specific method
    $r->content_type($writer->mimeType($resp)) ;
    $resp->cleanup() ;
    my $respTxt = $writer->asBytes($resp) ;
    if ( $retCode && ( $retCode  != Apache2::Const::HTTP_OK ) ){
        $r->status($retCode);
    }
    if ( $retCode && $retCode =~ /^2/ ){
        $r->headers_out()->add('Content-length' , length($respTxt)) ;
    }else{
        $r->err_headers_out()->add('Content-length' , length($respTxt)) ;
    }

    binmode STDOUT ;
    print $respTxt  ;
    return  Apache2::Const::OK ;

}


=head1 AUTHORS

Jerome Eteve, C<< <jerome at eteve.net> >>

Scott Thoman, C<< <scott dot thoman at steeleye dot com> >>

=head1 BUGS

Please report any bugs or feature requests to

L<http://code.google.com/p/apache2rest/issues/list>

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find reference documentation for this module with the perldoc command.

    perldoc Apache2::REST

You can find the wiki with Cooking recipes and in depth articles at:

L<http://code.google.com/p/apache2rest/w/list>


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-REST>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-REST>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-REST>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 The authors, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::REST
