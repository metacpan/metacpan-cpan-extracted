
package ASP4::HTTPContext;

use strict;
use warnings 'all';
use HTTP::Date ();
use HTTP::Headers ();
use ASP4::ConfigLoader;
use ASP4::Request;
use ASP4::Response;
use ASP4::Server;
use ASP4::OutBuffer;
use ASP4::SessionStateManager::NonPersisted;
use Carp 'confess';

use vars '$_instance';

sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    config => ASP4::ConfigLoader->load,
    buffer => [ ASP4::OutBuffer->new ],
    stash  => { },
    headers_out => HTTP::Headers->new(),
    is_subrequest => $args{is_subrequest},
  }, $class;
  $s->config->_init_inc();
  
  my $web = $s->config->web;
  $s->config->load_class( $web->handler_resolver );
  $s->config->load_class( $web->handler_runner );
  $s->config->load_class( $s->config->data_connections->session->manager );
  $s->config->load_class( $web->filter_resolver );
  
  return $s->is_subrequest ? $s : $_instance = $s;
}# end new()


sub setup_request
{
  my ($s, $r, $cgi) = @_;
  
  $ENV{DOCUMENT_ROOT} = $r->document_root;
  $s->{r} = $r;
  $s->{cgi} = $cgi;
  
  # Must instantiate $_instance before creating the other objects:
  $s->{request}   ||= ASP4::Request->new();
  $s->{response}  ||= ASP4::Response->new();
  $s->{server}    ||= ASP4::Server->new();
  
  if( $s->do_disable_session_state )
  {
    $s->{session} ||= ASP4::SessionStateManager::NonPersisted->new( $s->r );
  }
  else
  {
    $s->{session} ||= $s->config->data_connections->session->manager->new( $s->r );
  }# end if()
  
  return $_instance;
}# end setup_request()


# Intrinsics:
sub current   { $_instance || shift->new }
sub request   { shift->{request} }
sub response  { shift->{response} }
sub server    { shift->{server} }
sub session   { shift->{session} }
sub config    { shift->{config} }
sub stash     { shift->{stash} }

# More advanced:
sub is_subrequest { shift->{is_subrequest} }
sub cgi         { shift->{cgi} }
sub r           { shift->{r} }
sub handler     { shift->{handler} }
sub headers_out { shift->{headers_out} }
sub content_type  { my $s = shift; $s->r->content_type( @_ ) }
sub status        { my $s = shift; $s->r->status( @_ ) }
sub did_send_headers  { shift->{did_send_headers} }
sub did_end {
  my $s = shift;
  @_ ? $s->{did_end} = shift : $s->{did_end};
}

sub rprint {
  my ($s,$str) = @_;
  $s->buffer->add( $str );
}

sub rflush {
  my $s = shift;
  $s->send_headers;
  $s->r->print( $s->buffer->data );
  $s->r->rflush;
  $s->rclear;
}

sub rclear {
  my $s = shift;
  $s->buffer->clear;
}

sub send_headers
{
  my $s = shift;
  return if $s->{did_send_headers};
  
  my $headers = $s->headers_out;
  while( my ($k,$v) = each(%$headers) )
  {
    $s->r->err_headers_out->{$k} = $v;
  }# end while()

  $s->r->rflush;
  $s->{did_send_headers} = 1;
}# end send_headers()

# Here be dragons:
sub buffer        { shift->{buffer}->[-1] }
sub add_buffer    {
  my $s = shift;
  $s->rflush;
  push @{$s->{buffer}}, ASP4::OutBuffer->new;
}
sub purge_buffer  { shift( @{shift->{buffer}} ) }


sub execute
{
  my ($s, $args, $is_include) = @_;
  
  unless( $is_include )
  {
    # Set up and execute any matching request filters:
    my $resolver = $s->config->web->filter_resolver;
    foreach my $filter ( $resolver->new()->resolve_request_filters( $s->r->uri ) )
    {
      $s->config->load_class( $filter->class );
      $filter->class->init_asp_objects( $s );
      my $IS_FILTER = 1;
      my $res = $s->handle_phase(sub{ $filter->class->new()->run( $s ) }, $IS_FILTER);
      if( $s->did_end || ( defined($res) && $res != -1 ) )
      {
        return $res;
      }# end if()
    }# end foreach()
  }# end unless()
  
  eval {
    $s->{handler} = $s->config->web->handler_resolver->new()->resolve_request_handler( $s->r->uri );
  };
  
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()

  return $s->response->Status( 404 ) unless $s->{handler};
  
  eval {
    $s->config->load_class( $s->handler );
    $s->config->web->handler_runner->new()->run_handler( $s->handler, $args );
  };
  
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()
  
  $s->response->Flush;
  my $res = $s->end_request();
  
  $res = 0 if $res =~ m/^200/;
  return $res;
}# end execute()


sub handle_phase
{
  my ($s, $ref, $is_filter) = @_;
  
  my $res = eval { $ref->( ) };
  if( $@ )
  {
    $s->handle_error;
  }# end if()
  
  # Undef on success:
  if( $is_filter )
  {
    if( defined($res) && $res > -1 )
    {
      $s->response->Status( $res );
      return $res;
    }
    else
    {
      return;
    }# end if()
  }
  else
  {
    return if (! defined($res)) || $res == -1;
    return $s->response->Status =~ m/^200/ ? undef : $s->response->Status;
  }# end if()
}# end handle_phase()


sub handle_error
{
  my $s = shift;
  
  $s->response->Status( 500 );
  $s->response->Clear();
  my $err_str = $@;
  my $error = $s->server->Error( $@ );
  warn "[Error: @{[ HTTP::Date::time2iso() ]}] $err_str\n";
  
  return $s->end_request;
}# end handle_error()


sub end_request
{
  my $s = shift;
  
  $s->response->End;
  my $res = $s->response->Status =~ m/^200/ ? 0 : $s->response->Status;
  
  return $res;
}# end end_request()


sub do_disable_session_state
{
  my ($s) = @_;
  
#  my ($uri) = split /\?/, $s->r->uri;
  my ($uri) = split /\?/, $ENV{REQUEST_URI} || $s->r->uri;
  my ($yes) = grep { $_->disable_session } grep {
    if( my $pattern = $_->uri_match )
    {
      $uri =~ m/^$pattern$/
    }
    else
    {
      $uri eq $_->uri_equals;
    }# end if()
  } $s->config->web->disable_persistence;
  
  return $yes;
}# end do_disable_session_state()


sub DESTROY
{
  my $s = shift;
  $s->session->save if $s->session && ! $s->session->is_read_only;
  $s = { };
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::HTTPContext - Provides access to the intrinsic objects for an HTTP request.

=head1 SYNOPSIS

  use ASP4::HTTPContext;
  
  my $context = ASP4::HTTPContext->current;
  
  # Intrinsics:
  my $request   = $context->request;
  my $response  = $context->response;
  my $session   = $context->session;
  my $server    = $context->server;
  my $config    = $context->config;
  my $stash     = $context->stash;
  
  # Advanced:
  my $cgi = $context->cgi;
  my $r = $context->r;

=head1 DESCRIPTION

The HTTPContext itself is the root of all request-processing in an ASP4 web application.

There is only one ASP4::HTTPContext instance throughout the lifetime of a request.

=head1 PROPERTIES

=head2 current

Returns the C<ASP4::HTTPContext> object in use for the current HTTP request.

=head2 request

Returns the L<ASP4::Request> for the HTTP request.

=head2 response

Returns the L<ASP4::Response> for the HTTP request.

=head2 server

Returns the L<ASP4::Server> for the HTTP request.

=head2 session

Returns the L<ASP4::SessionStateManager> for the HTTP request.

=head2 stash

Returns the current stash hash in use for the HTTP request.

=head2 config

Returns the current C<ASP4::Config> for the HTTP request.

=head2 cgi

Provided B<Just In Case> - returns the L<CGI> object for the HTTP request.

=head2 r

Provided B<Just In Case> - returns the L<Apache2::RequestRec> for the HTTP request.

B<NOTE:> Under L<ASP4::API> (eg: in a unit test) C<$r> will be an instance of L<ASP4::Mock::RequestRec> instead.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

