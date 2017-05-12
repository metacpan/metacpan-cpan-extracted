package Continuity::Adapt::PSGI;

=head1 NAME

Continuity::Adapt::PSGI - PSGI backend for Continuity

=head1 SYNOPSIS

  # Run with on of these:
  #   corona demo.pl
  #   twiggy demo.pl
  #   ./myapp.pl # Will try to fall back to HttpDaemon ;)

  # "Twiggy is a lightweight and fast HTTP server"
  # "Corona is a Coro based Plack web server. It uses Net::Server::Coro under the hood"

  use Continuity;

  my $server = Continuity->new;

  sub main {
    my $request = shift;
    my $i = 0;
    while(++$i) {
      $request->print("Hello number $i!");
      $request->next;
    }
  }

  # This is actually returning a subref to PSI/Plack
  # So put it at the end
  $server->loop;

=cut

use strict;
use warnings;

use Continuity::Request;
use base 'Continuity::Request';

use Coro;
use Coro::Channel;
use Plack;
use Plack::App::File; # use this now; no surprises for later

warn "tested against Plack 0.9938; you have $Plack::VERSION" if $Plack::VERSION < 0.9938;

sub debug_level { exists $_[1] ? $_[0]->{debug_level} = $_[1] : $_[0]->{debug_level} }

sub debug_callback { exists $_[1] ? $_[0]->{debug_callback} = $_[1] : $_[0]->{debug_callback} }

sub docroot { exists $_[1] ? $_[0]->{docroot} = $_[1] : $_[0]->{docroot} }

sub new {
  my $class = shift;
  bless {
    first_request => 1,
    debug_level => 1,
    debug_callback => sub { print STDERR "@_\n" },
    request_queue => Coro::Channel->new(),
    @_
  }, $class;
}

sub get_request {
  # called from Continuity's main loop (new calls start_request_loop; start_request_loop gets requests from here or wherever and passes them to the mapper)
  my ($self) = @_;
  my $request = $self->{request_queue}->get or die;
  return $request;
}

sub loop_hook {

  my $self = shift;

  # $server->loop calls this; plackup run .psgi files except a coderef as the
  # last value and this lets that coderef fall out of the call to
  # $server->loop.

  # unique to the PSGI adapter -- a coderef that gets invoked when a request
  # comes in

  my $app = sub {
    my $env = shift;

    unless ($env->{'psgi.streaming'}) {
      die 'This application needs psgi.streaming support!';
    }

    # stuff $env onto a queue that get_request above pulls from; get_request is
    # called from Continuity's main execution context/loop. Continuity's main
    # execution loop invokes the Mapper to send the request across a queue to
    # the per session execution context (creating a new one as needed).

    return sub {
      my $response = shift;

      async {
        local $Coro::current->{desc} = 'PSGI Response Maker';

        # make it now and send it through the queue fully formed
        my $request = Continuity::Adapt::PSGI::Request->new( $env, $response );
        $self->{request_queue}->put($request);

        # Now... we wait!
        $request->{response_done_watcher}->wait;
      };
    };
  };

  # Is this needed?
  Coro::cede();

  return $app;
}

=head2 C<< $adapter->map_path($path) >>

Decodes URL-encoding in the path and attempts to guard against malice.
Returns the processed filesystem path.

=cut

sub map_path {
  my $self = shift;
  my $path = shift() || '';
  my $docroot = $self->docroot || '';
  # my $docroot = Cwd::getcwd();
  # $docroot .= '/' if $docroot and $docroot ne '.' and $docroot !~ m{/$};
  # some massaging, also makes it more secure
  $path =~ s/%([0-9a-fA-F][0-9a-fA-F])/chr hex $1/ge;
  $path =~ s%//+%/%g unless $docroot;
  $path =~ s%/\.(?=/|$)%%g;
  $path =~ s%/[^/]+/\.\.(?=/|$)%%g;

  # if($path =~ m%^/?\.\.(?=/|$)%) then bad

$self->Continuity::debug(2,"path: $docroot$path\n");

  return "$docroot$path";
}


sub send_static {
  my ($self, $r) = @_;

  # this is called from Continuity.pm to give a request back to us to deal with that it got from our get_request.
  # rather than sending it to the mapper to get sent to the per-user execution context, it gets returned straight back here.
  # $r is an instance of Continuity::Adapt::PSGI::Request

  my $url_path = $r->url_path;

  $url_path =~ s{\?.*}{};
  my $path = $self->map_path($url_path) or do { 
       $self->Continuity::debug(1, "can't map path: " . $url_path);
       # die; # XXX don't die except in debugging
      ( $r->{response_code}, $r->{response_headers}, $r->{response_content} ) = ( 404, [], [ "Static file not found" ] );
      $r->{response_done_watcher}->send;
      return;
  };

  my $stuff = Plack::App::File->serve_path({},$path);

  ( $r->{response_code}, $r->{response_headers}, $r->{response_content} ) = @$stuff;
  $r->response->(
    [ $r->response_code, $r->response_headers, $r->response_content ]
  );
  $r->{response_done_watcher}->send;

}

#
#
#

package Continuity::Adapt::PSGI::Request;

use Coro::Signal;
use Coro::AnyEvent;

# List of cookies to send
sub cookies { exists $_[1] ? $_[0]->{cookies} = $_[1] : $_[0]->{cookies} }

# Flag, never send type
sub no_content_type { exists $_[1] ? $_[0]->{no_content_type} = $_[1] : $_[0]->{no_content_type} }

# CGI query params
sub cached_params { exists $_[1] ? $_[0]->{cached_params} = $_[1] : $_[0]->{cached_params} }

# The writer is kinda like our connection
sub writer { exists $_[1] ? $_[0]->{writer} = $_[1] : $_[0]->{writer} }
sub response { exists $_[1] ? $_[0]->{response} = $_[1] : $_[0]->{response} }

sub response_code { exists $_[1] ? $_[0]->{response_code} = $_[1] : $_[0]->{response_code} }
sub response_headers { exists $_[1] ? $_[0]->{response_headers} = $_[1] : $_[0]->{response_headers} }
sub response_content { exists $_[1] ? $_[0]->{response_content} = $_[1] : $_[0]->{response_content} }

sub debug_level { exists $_[1] ? $_[0]->{debug_level} = $_[1] : $_[0]->{debug_level} }

sub debug_callback { exists $_[1] ? $_[0]->{debug_callback} = $_[1] : $_[0]->{debug_callback} }

sub new {
  my ($class, $env, $response) = @_;
  my $self = {
    response_code => 200,
    response_headers => [],
    response_content => [],
    response_done_watcher => Coro::Signal->new,
    response => $response,
    debug_level => 3,
    debug_callback => sub { print STDERR "@_\n" },
    %$env
  };
  bless $self, $class;
  return $self;
}

sub param {
    my $self = shift; 
    my $env = { %$self };
    unless($self->cached_params) {
      use Plack::Request;
      my $req = Plack::Request->new($env);
      $self->cached_params( [ %{$req->parameters} ] );
    };
    my @params = @{ $self->cached_params };
    if(@_) {
        my @values;
        while(@_) {
          my $param = shift;
          for(my $i = 0; $i < @params; $i += 2) {
              push @values, $params[$i+1] if $params[$i] eq $param;
          }
        }
        return unless @values;
        return wantarray ? @values : $values[0];
    } else {
        return @{$self->cached_params};
    }
}

sub params {
    my $self = shift;
    $self->param;
    return @{$self->cached_params};
}

sub method {
  my ($self) = @_;
  return $self->{REQUEST_METHOD};
}

sub url {
  my ($self) = @_;
  return $self->{'psgi.url_scheme'} . '://' . $self->{HTTP_HOST} . $self->{PATH_INFO};
}

sub url_path {
  my ($self) = @_;
  return $self->{PATH_INFO};
}

sub uri {
  my $self = shift;
  return $self->url(@_);
}

sub set_cookie {
    my $self = shift;
    my $cookie = shift;
    # record cookies and then send them the next time send_basic_header() is called and a header is sent.
    #$self->{Cookie} = $self->{Cookie} . "Set-Cookie: $cookie";
    push @{ $self->{response_headers} }, "Set-Cookie" => "$cookie";
}

sub get_cookie {
    my $self = shift;
    my $cookie_name = shift;
    my ($cookie) =  map $_->[1],
      grep $_->[0] eq $cookie_name,
      map [ m/(.*?)=(.*)/ ],
      split /; */,
      $self->{HTTP_COOKIE} || '';
    return $cookie;
}

sub immediate { }

sub send_basic_header {
    my $self = shift;
    my $cookies = $self->cookies;
    $self->cookies('');

    unless($self->no_content_type) {
      push @{ $self->{response_headers} },
           "Cache-Control" => "private, no-store, no-cache",
           "Pragma" => "no-cache",
           "Expires" => "0",
           "Content-type" => "text/html",
      ;
    }

    my $writer = $self->response->(
      [ $self->response_code, $self->response_headers ]
    );
    
    $self->writer( $writer );
}

sub print {
  my $self = shift;

  eval {
    $self->writer->write( @_ );
  };

  # This is a good time to let other stuff run
  Coro::AnyEvent::idle();

  return $self;
}

sub end_request {
  my $self = shift;
  
  # Tell our writer that we're done
  $self->writer->close if $self->writer;

  # Signal that we are done building our response
  $self->{response_done_watcher}->send;
}

1;
