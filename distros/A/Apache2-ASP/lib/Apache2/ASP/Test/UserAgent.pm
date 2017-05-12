
package Apache2::ASP::Test::UserAgent;

use strict;
use warnings 'all';
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Request::AsCGI;
use HTTP::Body;
use Apache2::ASP::HTTPContext;
use Apache2::ASP::SimpleCGI;
use Apache2::ASP::Mock::RequestRec;
use Carp 'confess';
use IO::File;
use Scalar::Util 'weaken';
use Cwd 'cwd';

our $ContextClass = 'Apache2::ASP::HTTPContext';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  return bless {
    cwd => cwd(),
    %args,
  }, $class;
}# end new()


#==============================================================================
sub context
{
  my $s = shift;
  chdir( $s->{cwd} );
  return Apache2::ASP::HTTPContext->current || $Apache2::ASP::HTTPContext::ClassName->new;
}# end context()


#==============================================================================
sub post
{
  my ($s, $uri, $args) = @_;
  
  chdir( $s->{cwd} );
  no strict 'refs';
  undef(${"$ContextClass\::instance"});
  $args ||= [ ];
  my $req = POST $uri, $args;
  {
    no warnings 'uninitialized';
    %ENV = ( DOCUMENT_ROOT => $ENV{DOCUMENT_ROOT} );
  }
  $ENV{REQUEST_METHOD} = 'POST';
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $uri );
  $r->args( $cgi->{querystring} );
  $r->{headers_in}->{Cookie} = $ENV{HTTP_COOKIE};
  
  $s->context->setup_request( $r, $cgi );
  return $s->_setup_response( $s->context->execute() );
}# end post()


#==============================================================================
sub upload
{
  my ($s, $uri, $args) = @_;
  
  chdir( $s->{cwd} );
  no strict 'refs';
  undef(${"$ContextClass\::instance"});
  {
    no warnings 'uninitialized';
    %ENV = ( DOCUMENT_ROOT => $ENV{DOCUMENT_ROOT} );
  }
  my $req = POST $uri, Content_Type => 'form-data', Content => $args;
  $ENV{REQUEST_METHOD} = 'POST';
  $ENV{CONTENT_TYPE} = $req->headers->{'content-type'};
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = 'multipart/form-data';
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $uri );
  $r->args( $cgi->{querystring} );
  $r->{headers_in}->{Cookie} = $ENV{HTTP_COOKIE};
  
  $s->context->setup_request( $r, $cgi );
  
  require Apache2::ASP::UploadHook;
  my $handler_resolver = $s->context->config->web->handler_resolver;
  $s->context->config->load_class( $handler_resolver );
  my $hook_obj = Apache2::ASP::UploadHook->new(
    handler_class => $handler_resolver->new()->resolve_request_handler( $uri ),
  );
  my $hook_ref = sub { $hook_obj->hook( @_ ) };
  
  # Now call the upload hook...
  require Apache2::ASP::Test::UploadObject;
  foreach my $uploaded_file ( keys( %{ $cgi->{uploads} } ) )
  {
    my $tmpfile = $cgi->upload_info($uploaded_file, 'tempname' );
    my $filename = $cgi->upload_info( $uploaded_file, 'filename' );
    my $ifh = IO::File->new;
    $ifh->open($tmpfile, '<')
      or die "Cannot open temp file '$tmpfile' for reading: $!";
    binmode($ifh);
    while( my $line = <$ifh> )
    {
      $hook_ref->(
        Apache2::ASP::Test::UploadObject->new(
          filename        => $filename,
          upload_filename => $filename
        ),
        $line
      );
    }# end while()
    close($ifh);
    
    # One more *without* any data (this will signify and EOF condition):
    $hook_ref->(
      Apache2::ASP::Test::UploadObject->new(
        filename        =>  $filename,
        upload_filename => $filename
      ),
      undef
    );
  }# end foreach()
  
  # NOW we can execute...
  return $s->_setup_response( $s->context->execute() );
}# end upload()


#==============================================================================
sub submit_form
{
  my ($s, $form) = @_;
  
  chdir( $s->{cwd} );
  no strict 'refs';
  undef(${"$ContextClass\::instance"});

  my $temp_referrer = $ENV{HTTP_REFERER};
  my $req = $form->click;
  
  {
    no warnings 'uninitialized';
    %ENV = ( DOCUMENT_ROOT => $ENV{DOCUMENT_ROOT} );
  }
  $ENV{REQUEST_METHOD} = uc( $req->method );
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = $form->enctype ? $form->enctype : 'application/x-www-form-urlencoded';
  $ENV{HTTP_REFERER} = $temp_referrer;
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $req->uri );
  $r->args( $cgi->{querystring} );
  $r->{headers_in}->{Cookie} = $ENV{HTTP_COOKIE};
  
  $s->context->setup_request( $r, $cgi );
  
  return $s->_setup_response( $s->context->execute() );
}# end submit_form()


#==============================================================================
sub get
{
  my ($s, $uri) = @_;
  
  chdir( $s->{cwd} );
  no strict 'refs';
  undef(${"$ContextClass\::instance"});
  
  my $req = GET $uri;
  {
    no warnings 'uninitialized';
    %ENV = ( DOCUMENT_ROOT => $ENV{DOCUMENT_ROOT} );
  }
  $ENV{REQUEST_METHOD} = 'GET';
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $uri );
  $r->args( $cgi->{querystring} );
  $r->{headers_in}->{Cookie} = $ENV{HTTP_COOKIE};
  
  $s->context->setup_request( $r, $cgi );  
  
  return $s->_setup_response( $s->context->execute() );
}# end get()


#==============================================================================
sub add_cookie
{
  my ($s, $name, $value) = @_;
  
  $s->{cookies}->{$name} = $value;
}# end add_cookie()


#==============================================================================
sub _setup_response
{
  my ($s, $response_code) = @_;
  
  $response_code = 200 if $response_code == 0;
  my $response = HTTP::Response->new( $response_code );
  $response->content( $s->context->get_prop('r')->buffer );
  
  $response->header( 'Content-Type' => $s->context->response->{ContentType} );
  
  foreach my $header ( $s->context->response->Headers )
  {
    while( my ($k,$v) = each(%$header) )
    {
      $response->header( $k => $v );
      if( lc($k) eq 'set-cookie' )
      {
        my ($data) = split /;/, $v;
        my ($name,$val) = map { Apache2::ASP::SimpleCGI->unescape( $_ ) } split /\=/, $data;
        $s->add_cookie( $name => $val );
      }# end if()
    }# end while()
  }# end foreach()
  
  if( $s->context->session && $s->context->session->{SessionID} )
  {
    $s->add_cookie(
      $s->context->config->data_connections->session->cookie_name => $s->context->session->{SessionID}
    );
  }# end if()
  
  $s->context->r->pool->call_cleanup_handlers();
  weaken($s->context->{cgi});
  
  return $response;
}# end _setup_response()


#==============================================================================
sub _setup_cgi
{
  my ($s, $req) = @_;
  
  my $docroot = $ENV{DOCUMENT_ROOT};
  $s->{c}->DESTROY
    if $s->{c};
  $req->referer( $s->{referer} || '' );
  ($s->{referer}) = $req->uri =~ m/.*?(\/[^\?]+)/;

  no warnings 'redefine';
  *HTTP::Request::AsCGI::stdout = sub { 0 };
  
  $s->{c} = HTTP::Request::AsCGI->new($req)->setup;
  $ENV{SERVER_NAME} = $ENV{HTTP_HOST} = 'localhost';
  
  unless( $req->uri =~ m@^/handlers@ )
  {
    my ($uri_no_args) = split /\?/, $req->uri;
    $ENV{SCRIPT_FILENAME} = $s->context->config->web->www_root . $uri_no_args;
    $ENV{SCRIPT_NAME} = $uri_no_args;
  }# end unless()
  
  # User-Agent:
  $req->header( 'User-Agent' => 'test-useragent v1.0' );
  $ENV{HTTP_USER_AGENT} = 'test-useragent v1.0';
  
  # Cookies:
  my @cookies = ();
  while( my ($name,$val) = each(%{ $s->{cookies} } ) )
  {
    next unless $name && $val;
    push @cookies, "$name=" . Apache2::ASP::SimpleCGI->escape($val);
  }# end while()
  
  $req->header( 'Cookie' => join ';', @cookies ) if @cookies;
  $ENV{HTTP_COOKIE} = join ';', @cookies;
  $ENV{DOCUMENT_ROOT} = $docroot
    if $docroot;
  
  if( $ENV{REQUEST_METHOD} =~ m/^post$/i )
  { 
    # Set up the basic params:
    return Apache2::ASP::SimpleCGI->new(
      querystring     => $ENV{QUERY_STRING},
      body            => $req->content,
      content_type    => $req->headers->{'content-type'},
      content_length  => $req->headers->{'content-length'},
    );
  }
  else
  {
    # Simple 'GET' request:
    return Apache2::ASP::SimpleCGI->new( querystring => $ENV{QUERY_STRING} );
  }# end if()
}# end _setup_cgi()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::Test::UserAgent - Execute ASP scripts without a webserver.

=head1 SYNOPSIS

Generally you will be accessing this class from wither L<Apache2::ASP::Test::Base>
or L<Apache2::ASP::API>.

  my $asp = Apache2::ASP::API->new()
    -- or --
  my $asp = Apache2::ASP::Test::Base->new();
  
  # Get:
  my $res = $asp->ua->get("/index.asp");
  if( $res->is_succes ) {
    ...
  }
  
  # Post:
  my $res = $asp->ua->post("/handlers/contact.form", [
    name  => "Fred",
    email => 'fred@flintstone.org',
    message => 'This is a test email message.'
  ]);
  
  # Do the same thing, but with HTML::Form:
  use HTML::Form;
  my $form = HTML::Form->parse( $asp->ua->get("/contact.asp")->content, '/' );
  $form->find_input('name')->value('Fred');
  $form->find_input('email')->value('fred@flintstone.org');
  $form->find_input('message')->value('This is a test email message');
  my $res = $asp->ua->submit_form( $form );
  
  # Upload:
  my $res = $asp->ua->upload("/handlers/MM?mode=create&uploadID=12334534", [
    filename => ['/path/to/file.txt'],
  ]);

=head1 PUBLIC PROPERTIES

=head2 context

Returns the current L<Apache2::ASP::HTTPContext> object.

=head1 PUBLIC METHODS

=head2 get( $url )

Makes a "GET" request to C<$url>

=head2 post( $url [,\@args] )

Makes a "POST" reqest to C<$url>, using C<@args> as the body.

=head2 upload( $url, \@args )

Makes a "POST" request with a C<multipart/form-data> type, using C<@args> as the body.

=head2 submit_form( HTML::Form $form )

Submits the form.

B<NOTE:> - this will not work for "upload" forms (yet).

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

