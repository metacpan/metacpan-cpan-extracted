package Apache::AxKit::Plugin::AddXSLParams::Request;

use strict;
use Apache::Constants;
use Apache::Cookie;
use Apache::Request;
use Apache::URI;
use vars qw($VERSION);
$VERSION = '1.02';


sub handler {
    my $r = shift;
    my $uri = $r->uri;
    my $cgi = Apache::Request->instance($r);
    my @allowed_groups = split /\s+/, $r->dir_config('AxAddXSLParamGroups') || ();
     
    # HTTP Headers
    if ( grep { $_ eq 'HTTPHeaders' } @allowed_groups ) {
        my $headers = $r->headers_in();
        foreach my $h ( keys( %{$headers} ) ) {
            #warn "Processing header " .  lc( $h ) . " = " . $headers->{$h} . " \n";
            if ( $h eq 'Cookie' ) {
                my $cookies = Apache::Cookie::parse( $headers->{$h} );
                foreach my $oreo ( keys( %{$cookies} ) ) {
                    $cgi->parms->set('request.cookie.' . $oreo => $cookies->{$oreo}->value ) if defined( $cookies->{$oreo}->value );

                }
            }
        
            $cgi->parms->set('request.headers.' . lc( $h ) => $headers->{$h});
        }
    }
            
    # Allow 'em to get Cookies header without all the other headers as an alternative
    elsif ( grep { $_ eq 'Cookies' } @allowed_groups ) {
        my $cookies = Apache::Cookie::parse( $r->header_in('Cookie') );
        foreach my $oreo ( keys( %{$cookies} ) ) {
            $cgi->parms->set('request.cookie.' . $oreo => $cookies->{$oreo}->value ) if defined( $cookies->{$oreo}->value );

        }
    }  
       
    # Here's the "Request-Common" group
    if ( grep { $_ eq 'Request-Common' } @allowed_groups ) {
        $cgi->parms->set('request.uri' => $r->uri );
        $cgi->parms->set('request.filename' => $r->filename);
        $cgi->parms->set('request.method' => $r->method);
        $cgi->parms->set('request.path_info' => $r->path_info) if length( $r->path_info ) > 0;
    }

    # verbose URI parameters
    if ( grep { $_ eq 'VerboseURI' } @allowed_groups ) {
        my $parsed_uri = $r->parsed_uri;

        my @uri_methods = qw( scheme hostinfo user password hostname port path rpath query fragment );
          
        foreach my $method ( @uri_methods ) {
            my $value = $parsed_uri->$method();
            $cgi->parms->set('request.uri.' . $method => $value ) if length $value > 0;
        }
    }
    return OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::Plugin::AddXSLParams::Request - Provides a way to pass info from the Apache::Request to XSLT params

=head1 SYNOPSIS

  # in httpd.conf or .htaccess
  AxAddPlugin Apache::AxKit::Plugin::AddXSLParams::Request
  PerlSetVar AxAddXSLParamGroups "Request-Common HTTPHeaders"

=head1 DESCRIPTION

A strong contender for longest package name of the year, Apache::AxKit::Plugin::AddXSLParams::Request offers a way to
make information about the current client request (cookies, headers, uri info) available as params within XSLT
stylesheets.

=head1 CONFIGURATION

This plugin is added to the request cycle by using the B<AxAddPlugin> directive.

  AxAddPlugin Apache::AxKit::Plugin::AddXSLParams::Request
  
This package introduces the B<AxAddXSLParamGroups> config option, which takes a space-seperated list of 'tags'
(see B<PARAM GROUPS> below) that are used to add groups of related information to the param list. Note
that this is I<not> a first-class config directive and must be added via B<PerlSetVar>:

  PerlSetVar AxAddXSLParamGroups "List Of Groups"

=head1 PARAM GROUPS

In an effort to provide an easy-to-setup way to make external data->XSL param mapping work
while letting folks choose only the types of info that they are interested in, sets of 
related information are grouped with an identifying 'tag'. This tag is passed in
via the B<AxAddXSLParamGroups> config directive which is used to determine which groups 
of info will be passed along as params. For example:

  AxAddXSLParamGroups "Request-Common HTTPHeaders VerboseURI"

will configure this package to include the sets of data identified by the
B<Request-Common>, B<HTTPHeaders>, and  B<VerboseURI> tags.

The param groups that this package implements are detailed below.

=head1 B<Request-Common>

A minimal set of common parameters extracted from the request instance.

B<Param Prefix>: request.*

B<Implemented Fields>:

=over 4

=item * uri

The full URI of the current request. 

=item * method 

The request method (POST, GET, etc.).

=item * path_info

Additional path information.

=item * filename

The file name associated with the current request.

=back

B<Examples>:

  <xsl:param name="request.method"/>
  <xsl:param name="request.uri"/>
  <xsl:param name="request.path_info"/>
  <xsl:param name="request.filename"/>
  
=head1 B<HTTPHeaders>

Provides access to HTTP headers sent by the client.

B<Param Prefix>: request.headers.*

B<Implemented Fields>:

The headers sent during a request vary somewhat from client to client; this
group will contain I<all> the headers returned by the request object's
headers_in() method using the convention: request.headers.I<fieldname> where
I<fieldname> is name of the given HTTP header field, forced to lower case.

If any HTTP Cookies are found in the headers, they will be parsed and values available as XSLT
params using the naming convention: request.cookies.I<yourcookiename>. See the B<Cookies> group
below for an alternative way to access cookies.

More common headers include:

=over 4

=item * accept

=item * content-type

=item * accept-charset

=item * accept-encoding

=item * accept-language

=item * connection

=item * host

=item * pragma

=item * user-agent

=item * from

=item * referer

=back

B<Examples>:

  <xsl:param name="request.headers.accept-language"/>
  <xsl:param name="request.headers.host"/>
  <xsl:param name="request.headers.user-agent"/>
  <xsl:param name="request.headers.referer"/>

=head1 B<Cookies>

Provides an I<alternative> way to access the HTTP Cookies header for those folks
that want to get at the cookie data but don't want to pull in all of the other
HTTP headers.

B<Param Prefix>: request.cookies.*

B<Implemented Fields>:

Cookie values are made available as params using the convention: request.cookies.I<yourcookiename>

B<Examples>:

  <xsl:param name="request.cookies.oreo"/>
  <xsl:param name="request.cookies.chocolate-chip"/>
  <xsl:param name="request.cookies.fortune"/>

=head1 B<VerboseURI>

Offers fine-grained access to the URI requested (via Apache::URI's parse_uri() method.

B<Param Prefix>: request.uri.*

B<Implemented Fields>:

=over 4

=item * scheme

=item * hostinfo

=item * user

=item * password

=item * hostname

=item * port

=item * path

=item * rpath

=item * query

=item * fragment

=back

B<Examples>:

  <xsl:param name="request.uri.path"/>
  <xsl:param name="request.uri.scheme"/>
  <xsl:param name="request.uri.port"/>

=head1 DEPENDENCIES

=over 4

=item * libapreq

=item * Apache::Request

=item * Apache::Cookie

=item * Apache::URI

=item * AxKit (1.5 or greater)

=back

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 SEE ALSO

AxKit, Apache::Request, libapreq, Apache::Cookie, Apache::URI

=cut
