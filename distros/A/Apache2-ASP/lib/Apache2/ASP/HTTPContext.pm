
package Apache2::ASP::HTTPContext;

use strict;
use warnings 'all';
use Apache2::ASP::ConfigLoader;
use Apache2::ASP::Response;
use Apache2::ASP::Request;
use Apache2::ASP::Server;
use Carp qw( cluck confess );
use Scalar::Util 'weaken';
use HTTP::Headers;

use Apache2::ASP::SessionStateManager::NonPersisted;
use Apache2::ASP::ApplicationStateManager::NonPersisted;

our $instance;
our $ClassName = __PACKAGE__;
our %StartedServers = ( );

#==============================================================================
sub current
{
  my $class = shift;
  
  return $instance;
}# end current()


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    config  => Apache2::ASP::ConfigLoader->load(),
  }, $class;
  $s->config->_init_inc();
  
  return $instance = $s;
}# end new()


#==============================================================================
sub setup_request
{
  my ($s, $requestrec, $cgi) = @_;
  
  $s->{_is_setup}++;
  
  $s->{r} = $requestrec;
  $s->{cgi} = $cgi;

  $s->_setup_headers_out();
  $s->_setup_headers_in();
  
  $s->{connection}  = $s->r->connection;
  
  $s->{response} = Apache2::ASP::Response->new();
  $s->{request}  = Apache2::ASP::Request->new();
  $s->{server}   = Apache2::ASP::Server->new();

  my $conns = $s->config->data_connections;
  if( $s->do_disable_application_state )
  {
    $s->{application} = Apache2::ASP::ApplicationStateManager::NonPersisted->new();
  }
  else
  {
    my $app_manager = $conns->application->manager;
    $s->_load_class( $app_manager );
    $s->{application} = $app_manager->new();
  }# end if()
  
  if( $s->do_disable_session_state )
  {
    $s->{session} = Apache2::ASP::SessionStateManager::NonPersisted->new();
  }
  else
  {
    my $session_manager = $conns->session->manager;
    $s->_load_class( $session_manager );
    $s->{session} = $session_manager->new();
  }# end if()
  
  # Make the global Stash object:
  $s->{stash} = { };
    
  $s->{global_asa} = $s->resolve_global_asa_class( );
  {
    no warnings 'uninitialized';
    $s->{global_asa}->init_asp_objects( $s )
      unless $s->r->headers_in->{'content-type'} =~ m/multipart/;
  }
  
  $s->_load_class( $s->config->web->handler_resolver );
  eval {
    $s->{handler} = $s->config->web->handler_resolver->new()->resolve_request_handler( $s->r->uri );
  };
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()
  
  return 1;
}# end setup_request()


#==============================================================================
sub _setup_headers_out
{
  my ($s) = @_;
  
  $s->{headers_out} = HTTP::Headers->new();
}# end _setup_headers_out()


#==============================================================================
sub _setup_headers_in
{
  my ($s) = @_;
  
  my $h = $s->r->headers_in;
  if( UNIVERSAL::isa($h, 'HTTP::Headers') )
  {
    $s->{headers_in} = $h;
  }
  else
  {
    my $headers_in = HTTP::Headers->new();
    while( my ($k,$v) = each(%$h) )
    {
      $headers_in->push_header( $k => $v );
    }# end while()
    $s->{headers_in} = $headers_in;
  }# end if()
}# end _setup_headers_in()


#==============================================================================
sub do_disable_session_state
{
  my ($s) = @_;
  
  my ($uri) = split /\?/, $s->r->uri;
  my ($yes) = grep { $_->disable_session } grep {
    if( my $pattern = $_->uri_match )
    {
      $uri =~ m/$pattern/
    }
    else
    {
      $uri eq $_->uri_equals;
    }# end if()
  } $s->config->web->disable_persistence;
  
  return $yes;
}# end do_disable_session_state()


#==============================================================================
sub do_disable_application_state
{
  my ($s) = @_;
  
  my ($uri) = split /\?/, $s->r->uri;
  my ($yes) = grep { $_->disable_application } grep {
    if( my $pattern = $_->uri_match )
    {
      $uri =~ m/$pattern/
    }
    else
    {
      $uri eq $_->uri_equals;
    }# end if()
  } $s->config->web->disable_persistence;
  
  return $yes;
}# end do_disable_application_state()


#==============================================================================
sub execute
{
  my ($s, $args) = @_;

#  local $SIG{__DIE__} = \&Carp::confess;

  return 404 unless $s->handler;
  
  if( defined(my $preinit_res = $s->do_preinit) )
  {
    return $preinit_res;
  }# end if()
  
  # Set up and execute any matching request filters:
  my $resolver = $s->config->web->filter_resolver;
  $s->_load_class( $resolver );
  foreach my $filter ( $resolver->new()->resolve_request_filters( $s->r->uri ) )
  {
    $s->_load_class( $filter->class );
    $filter->class->init_asp_objects( $s );
    my $res = $s->handle_phase(sub{ $filter->class->new()->run( $s ) });
    if( defined($res) && $res != -1 )
    {
      return $res;
    }# end if()
  }# end foreach()
  
  my $start_res = $s->handle_phase( $s->global_asa->can('Script_OnStart') );
  return $start_res if defined( $start_res );
  
  $s->_load_class( $s->config->web->handler_runner );
  eval {
    $s->_load_class( $s->handler );
    $s->config->web->handler_runner->new()->run_handler( $s->handler, $args );
  };
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()
  
  $s->response->Flush;
  my $res = $s->end_request();
#  if( $s->page && $s->page->directives->{OutputCache} && defined($s->{_cache_buffer}) )
#  {
#    if( $res == 200 || $res == 0 )
#    {
#      $s->page->_write_cache( \$s->{_cache_buffer} );
#    }# end if()
#  }# end if()
  
  $res = 0 if $res =~ m/^200/;
  return $res;
}# end execute()


#==============================================================================
#sub _setup_inc
#{
#  my $s = shift;
#
#  my $www_root = $s->config->web->www_root;
#  push @INC, $www_root unless grep { $_ eq $www_root } @INC;
#  my %libs = map { $_ => 1 } @INC;
#  push @INC, grep { ! $libs{$_} } $s->config->system->libs;
#}# end _setup_inc()


#==============================================================================
sub do_preinit
{
  my $s = shift;
  
  unless( $s->_is_setup )
  {
    $s->setup_request( $Apache2::ASP::ModPerl::R, $Apache2::ASP::ModPerl::CGI );
  }# end unless()
  
  # Initialize the Server, Application and Session:
  unless( $StartedServers{ $s->config->web->application_name } )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Server_OnStart')
    );
    $StartedServers{ $s->config->web->application_name }++
      unless $@;
    return $s->end_request if $s->{did_end};
  }# end unless()
  
  unless( $s->application->{__Application_Started} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Application_OnStart')
    );
    $s->application->{__Application_Started}++ unless $@;
    return $s->end_request if $s->{did_end};
  }# end unless()
  
  unless( $s->session->{__Started} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Session_OnStart')
    );
    $s->session->{__Started}++ unless $@;
    return $s->end_request if $s->{did_end};
  }# end unless()
  
  return;
}# end do_preinit()


#==============================================================================
sub handle_phase
{
  my ($s, $ref) = @_;
  
  eval { $ref->( ) };
  if( $@ )
  {
    $s->handle_error;
  }# end if()
  
  # Undef on success:
  return $s->response->Status =~ m/^200/ ? undef : $s->response->Status;
}# end handle_phase()


#==============================================================================
sub handle_error
{
  my $s = shift;
  
  my $error = "$@";
  $s->response->Status( 500 );
  no strict 'refs';

  $s->response->Clear;
  my ($main, $title, $file, $line) = $error =~ m/^((.*?)\s(?:at|in)\s(.*?)\sline\s(\d+))/;
  $s->stash->{error} = {
    title       => $title,
    file        => $file,
    line        => $line,
    stacktrace  => $error,
  };
  warn "[Error: @{[ HTTP::Date::time2iso() ]}] $main\n";
  
  $s->_load_class( $s->config->errors->error_handler );
  my $error_handler = $s->config->errors->error_handler->new();
  $error_handler->init_asp_objects( $s );
  eval { $error_handler->run( $s ) };
  confess $@ if $@;
  
  return $s->end_request;
}# end handle_error()


#==============================================================================
sub end_request
{
  my $s = shift;
  
  $s->handle_phase( $s->global_asa->can('Script_OnEnd') )
    unless $s->server->GetLastError;
  
  $s->response->End;
  $s->session->save;
  $s->application->save;
  my $res = $s->response->Status =~ m/^200/ ? 0 : $s->response->Status;
  
  return $res;
}# end end_request()


#==============================================================================
sub clone
{
  my $s = shift;
  
  return bless {%$s}, ref($s);
}# end clone()


#==============================================================================
sub get_prop
{
  my ($s, $prop) = @_;
  
  $s->{parent} ? $s->{parent}->get_prop($prop) : $s->{$prop};
}# end get_prop()


#==============================================================================
sub set_prop
{
  my ($s) = shift;
  my $prop = shift;
  
  $s->{parent} ? $s->{parent}->set_prop($prop, @_) : $s->{$prop} = shift;
}# end set_prop()

sub config       { $_[0]->get_prop('config') }
sub session      { $_[0]->get_prop('session')               }
sub server       { $_[0]->get_prop('server')                }
sub request      { $_[0]->get_prop('request')               }
sub response     { $_[0]->get_prop('response')              }
sub application  { $_[0]->get_prop('application')           }
sub stash        { $_[0]->get_prop('stash')                 }
sub global_asa   { $_[0]->get_prop('global_asa')            }
sub _is_setup    { $_[0]->get_prop('_is_setup')            }

sub r            { $_[0]->{r}                     }
sub cgi
{
  my $s = shift;
  $s->{cgi} ||= Apache2::ASP::SimpleCGI->new(
    querystring => $s->r->args
  );
  return $s->{cgi};
}
sub handler      { $_[0]->{handler}               }
sub connection   { $_[0]->{connection}            }
sub page         { $_[0]->{page}                  }

sub headers_in   { shift->get_prop('headers_in') }
sub send_headers
{
  my $s = shift;
#  return if $s->{_did_send_headers};
  return if $s->get_prop('_did_send_headers');
  
  my $headers = $s->get_prop('headers_out');
  my $r = $s->get_prop('r');
  while( my ($k,$v) = each(%$headers) )
  {
    $r->err_headers_out->{$k} = $v;
  }# end while()

  $r->rflush;
#  $s->{_did_send_headers} = 1;
  $s->set_prop(_did_send_headers => 1);
}# end send_headers()

sub headers_out  { shift->get_prop('headers_out') }
sub content_type { shift->get_prop('r')->content_type( @_ ) }


sub print
{
  my ($s, $str) = @_;
  
  $s->send_headers unless $s->get_prop('_did_send_headers');
  return unless defined($str);
  eval {
    $s->{r}->print( $str );
  };
}# end print()



#==============================================================================
sub rflush
{
  my $s = shift;
  
  $s->send_headers
    unless $s->did_send_headers;
  eval {
    $s->{r}->rflush();
  };
}# end rflush()

sub did_send_headers { shift->get_prop('_did_send_headers') }


#==============================================================================
sub resolve_global_asa_class
{
  my $s = shift;
  
  my $file = $s->config->web->www_root . '/GlobalASA.pm';
  my $class;
  if( -f $file )
  {
    $class = $s->config->web->application_name . '::GlobalASA';
    eval { require $file };
    confess $@ if $@;
  }
  else
  {
    $class = 'Apache2::ASP::GlobalASA';
    $s->_load_class( $class );
  }# end if()
  
  return $class;
}# end resolve_global_asa_class()


#==============================================================================
sub _load_class
{
  my ($s, $class) = @_;
  
  (my $file = "$class.pm") =~ s/::/\//g;
  eval { require $file; 1 }
    or confess "Cannot load $class: $@";
}# end _load_class()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ m/([^:]+)$/;
  @_ ? $s->set_prop( $key, shift ) : $s->get_prop( $key );
}# end AUTOLOAD()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  undef(%$s);
}# end DESTROY()

1;# return true:


=pod

=head1 NAME

Apache2::ASP::HTTPContext - Contextual execution harness for ASP scripts.

=head1 SYNOPSIS

  # Get the original mod_perl '$r' object:
  my Apache2::RequestRec $r = $context->r;
  
  # Get the other traditional ASP objects:
  my $Config      = $context->config;
  my $Request     = $context->request;
  my $Response    = $context->response;
  my $Server      = $context->server;
  my $Session     = $context->session;
  my $Application = $context->application;
  
  # Get the current context object from anywhere within your application:
  my $context = Apache2::ASP::HTTPContext->current;

=head1 DESCRIPTION

=head1 STATIC PROPERTIES

=head2 current

Returns the "current" HTTPContext instance.

=head1 PUBLIC PROPERTIES

=head2 r

Returns the current Apache2::RequestRec object.

B<NOTE>: while in "API" or "Testing" mode, C<r> returns the current 
L<Apache2::ASP::Mock::RequestRec> object.

=head2 config

Returns the current L<Apache2::ASP::Config> object.

=head2 request

Returns the current L<Apache2::ASP::Request> object.

=head2 response

Returns the current L<Apache2::ASP::Response> object.

=head2 server

Returns the current L<Apache2::ASP::Server> object.

=head2 session

Returns the current L<Apache2::ASP::Session> object.

=head2 application

Returns the current L<Apache2::ASP::Application> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

