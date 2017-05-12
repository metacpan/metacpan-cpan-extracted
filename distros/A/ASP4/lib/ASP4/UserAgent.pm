
package ASP4::UserAgent;

use strict;
use warnings 'all';
use Carp 'confess';
use Cwd 'fastcwd';
use HTTP::Request::Common;
use HTTP::Response;

use ASP4::HTTPContext;
use ASP4::ConfigLoader;
use ASP4::SimpleCGI;
use ASP4::Mock::RequestRec;

sub new
{
  return bless {
    cwd         => fastcwd(),
    http_cookie => '',
    cookies     => { },
    referer     => '',
    env         => { %ENV },
  }, shift;
}# end new()

sub context { shift->{context} }
sub config  { chdir(shift->{cwd}); ASP4::ConfigLoader->load }


sub get
{
  my ($s, $uri) = @_;
  
  chdir( $s->{cwd} );
  
  my $req = GET $uri;
  my $referer = $ENV{HTTP_REFERER};
  %ENV = (
    %{ $s->{env} },
    HTTP_HOST       => $s->{env}->{HTTP_HOST} || $s->{cwd},
    HTTP_REFERER    => $referer || '',
    DOCUMENT_ROOT   => $s->config->web->www_root,
    REQUEST_METHOD  => 'GET',
    CONTENT_TYPE    => 'application/x-www-form-urlencoded',
    HTTP_COOKIE     => $s->http_cookie,
    REQUEST_URI     => $uri,
  );
  my $cgi = $s->_setup_cgi( $req );
  my ($uri_no_args, $querystring) = split /\?/, $uri;
  my $r = ASP4::Mock::RequestRec->new( uri => $uri_no_args, args => $querystring );
  
  my $current_is_subrequest = $ASP4::HTTPContext::_instance ? $ASP4::HTTPContext::_instance->{is_subrequest} ? 1 : 0 : 0;
  $s->{context} = ASP4::HTTPContext->new( is_subrequest => $current_is_subrequest ? 1 : 0 );
  
  return do {
    local $ASP4::HTTPContext::_instance = $s->context;
    $s->context->setup_request( $r, $cgi );
    $s->_setup_response( $s->context->execute() );
  };
}# end get()


sub post
{
  my ($s, $uri, $args) = @_;
  
  chdir( $s->{cwd} );
  
  $args ||= [ ];
  my $req = POST $uri, $args;
  my $referer = $ENV{HTTP_REFERER};
  %ENV = (
    %{ $s->{env} },
    HTTP_REFERER    => $referer || '',
    DOCUMENT_ROOT   => $s->config->web->www_root,
    REQUEST_METHOD  => 'POST',
    CONTENT_TYPE    => 'application/x-www-form-urlencoded',
    HTTP_COOKIE     => $s->http_cookie,
    REQUEST_URI     => $uri,
  );
  my $cgi = $s->_setup_cgi( $req );
  my ($uri_no_args, $querystring) = split /\?/, $uri;
  my $r = ASP4::Mock::RequestRec->new( uri => $uri_no_args, args => $querystring );
  $s->{context} = ASP4::HTTPContext->new( is_subrequest => $ASP4::HTTPContext::_instance ? 1 : 0 );
  return do {
    local $ASP4::HTTPContext::_instance = $s->context;
    $s->context->setup_request( $r, $cgi );
    $s->_setup_response( $s->context->execute() );
  };
}# end post()


sub upload
{
  my ($s, $uri, $args) = @_;
  
  chdir( $s->{cwd} );
  
  $args ||= [ ];
  my $req = POST $uri, Content_Type => 'form-data', Content => $args;
  my $referer = $ENV{HTTP_REFERER};
  %ENV = (
    %{ $s->{env} },
    HTTP_REFERER    => $referer || '',
    DOCUMENT_ROOT   => $s->config->web->www_root,
    REQUEST_METHOD  => 'POST',
    CONTENT_TYPE    => 'multipart/form-data',
    HTTP_COOKIE     => $s->http_cookie,
    REQUEST_URI     => $uri,
  );
  my $cgi = $s->_setup_cgi( $req );
  my ($uri_no_args, $querystring) = split /\?/, $uri;
  my $r = ASP4::Mock::RequestRec->new( uri => $uri_no_args, args => $querystring );
  $s->{context} = ASP4::HTTPContext->new( is_subrequest => $ASP4::HTTPContext::_instance ? 1 : 0 );
  return do {
    local $ASP4::HTTPContext::_instance = $s->context;
    $s->context->setup_request( $r, $cgi );
    $s->_setup_response( $s->context->execute() );
  };
}# end upload()


sub submit_form
{
  my ($s, $form) = @_;
  
  chdir( $s->{cwd} );
  
  my $temp_referrer = $ENV{HTTP_REFERER};
  my $req = $form->click;
  my $referer = $ENV{HTTP_REFERER};
  %ENV = (
    %{ $s->{env} },
    HTTP_REFERER    => $referer || '',
    DOCUMENT_ROOT   => $s->config->web->www_root,
    REQUEST_METHOD  => uc( $req->method ),
    CONTENT_TYPE    => $form->enctype ? $form->enctype : 'application/x-www-form-urlencoded',
    HTTP_COOKIE     => $s->http_cookie,
    REQUEST_URI     => $form->action,
  );
  my $cgi = $s->_setup_cgi( $req );
  my ($uri_no_args, $querystring) = split /\?/, $req->uri;
  my $r = ASP4::Mock::RequestRec->new( uri => $uri_no_args, args => $querystring );
  my $current_is_subrequest = $ASP4::HTTPContext::_instance ? $ASP4::HTTPContext::_instance->{is_subrequest} ? 1 : 0 : 0;
  $s->{context} = ASP4::HTTPContext->new( is_subrequest => $current_is_subrequest ? 1 : 0 );
  return do {
    local $ASP4::HTTPContext::_instance = $s->context;
    $s->context->setup_request( $r, $cgi );
    $s->_setup_response( $s->context->execute() );
  };
}# end submit_form()


sub add_cookie
{
  my ($s, $name, $value) = @_;
  
  $s->{cookies}->{$name} = $value;
}# end add_cookie()


sub remove_cookie
{
  my ($s, $name) = @_;
  
  delete( $s->{cookies}->{$name} );
}# end remove_cookie()


sub http_cookie
{
  my $s = shift;
  
  join '; ',
    map { ASP4::SimpleCGI->escape($_) . '=' . ASP4::SimpleCGI->escape($s->{cookies}->{$_}) }
    keys %{$s->{cookies}};
}# end http_cookie()


sub _setup_response
{
  my ($s, $response_code) = @_;
  
  $response_code = 200 if ($response_code || 0) eq '0';
  my $response = HTTP::Response->new( $response_code );
  
  # XXX: Sometimes this dies with 'HTTP::Message requires bytes' or similar:
  eval { $response->content( $s->context->r->buffer ) };
  if( $@ )
  {
    (my $ascii = $s->context->r->buffer) =~ s/[^[:ascii:]]//gs;
    $response->content( $ascii );
  }# end if()
  
  $response->header( 'Content-Type' => $s->context->response->{ContentType} );
  
  foreach my $header ( $s->context->response->Headers, $s->context->r->err_headers_out )
  {
    if( my ($k,$v) = each(%$header) )
    {
      $response->header( lc($k) => $v );
      if( lc($k) eq 'set-cookie' )
      {
        my @cookies = ( );
        if( ref($v) )
        {
          @cookies = @$v;
        }
        else
        {
          @cookies = ( $v );
        }# end if()
        
        foreach $v ( @cookies )
        {
          my ($data) = split /;/, $v;
          my ($name,$val) = map { ASP4::SimpleCGI->unescape( $_ ) } split /\=/, $data;
          $s->add_cookie( $name => $val );
        }# end foreach()
      }# end if()
    }# end while()
  }# end foreach()
  
  $s->context->r->pool->call_cleanup_handlers();
  
#  $s->context->DESTROY;
  
  return $response;
}# end _setup_response()


sub _setup_cgi
{
  my ($s, $req) = @_;

  if( $s->{referer} )
  {
    ($s->{referer}) = $req->uri =~ m/.*?(\/[^\?]+)/;
    $req->referer( $s->{referer} );
  }
  else
  {
    $req->referer('');
  }# end if()
  
  no warnings 'uninitialized';
  (my ($uri_no_args), $ENV{QUERY_STRING} ) = split /\?/, $req->uri;
  $ENV{SERVER_NAME} = $ENV{HTTP_HOST} = 'localhost';
  
  unless( $req->uri =~ m@^/handlers@ )
  {
    $ENV{SCRIPT_FILENAME} = $s->config->web->www_root . $uri_no_args;
    if( -d $ENV{SCRIPT_FILENAME} )
    {
      $ENV{SCRIPT_FILENAME} =~ s{/$}{};
      $ENV{SCRIPT_FILENAME} .= "/index.asp";
    }# end if()
    $ENV{SCRIPT_NAME} = $uri_no_args;
  }# end unless()
  
  # User-Agent:
  $req->header( 'User-Agent' => 'test-useragent v2.0' );
  $ENV{HTTP_USER_AGENT} = 'test-useragent v2.0';
  
  # Cookies:
  $req->header( 'Cookie' => $ENV{HTTP_COOKIE} = $s->http_cookie );
  
  if( $ENV{REQUEST_METHOD} =~ m/^post$/i )
  { 
    # Set up the basic params:
    return ASP4::SimpleCGI->new(
      querystring     => $ENV{QUERY_STRING},
      body            => $req->content,
      content_type    => $req->headers->{'content-type'},
      content_length  => $req->headers->{'content-length'},
    );
  }
  else
  {
    # Simple 'GET' request:
    return ASP4::SimpleCGI->new( querystring => $ENV{QUERY_STRING} );
  }# end if()
}# end _setup_cgi()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::UserAgent - Execute ASP4 requests without a web server.

=head1 SYNOPSIS

B<NOTE:> 99.99% of the time you will access this via L<ASP4::API>.

  my HTTP::Response $res = $api->ua->get('/index.asp?foo=bar');
  
  my $res = $api->ua->post('/handlers/user.login', [
    username  => 'willy',
    password  => 'wonka',
  ]);
  
  my $res = $api->ua->upload('/handlers/file.upload', [
    foo   => 'bar',
    baz   => 'bux',
    file  => ['/home/john/avatar.jpg']
  ]);
  
  # Some form testing:
  my ($form) = HTML::Form->parse( $res->content, '/' );
  $form->find_input('username')->value('bob');
  my $res = $api->ua->submit_form( $form );
  
  # Add/remove a cookie:
  $api->ua->add_cookie( "the-boss" => "me" );
  $api->remove_cookie( "the-boss" );

=head1 DESCRIPTION

Enables unit-testing ASP4 applications by providing the ability to execuite web 
pages from your code, without a webserver.

=head1 PUBLIC METHODS

=head2 get( $url )

Calls C<$url> and returns the L<HTTP::Response> result.

=head2 post( $url, $args )

Calls C<$url> with C<$args> and returns the L<HTTP::Response> result.

=head2 upload( $url, $args )

Calls C<$url> with C<$args> and returns the L<HTTP::Response> result.

=head2 submit_form( HTML::Form $form )

Submits the C<$form> and returns the L<HTTP::Response> result.

=head2 add_cookie( $name, $value )

Adds the cookie to all subsequent requests.

=head2 remove_cookie( $name )

Removes the cookie (if it exists).

=head1 SEE ALSO

L<HTTP::Response> and L<HTML::Form>

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

