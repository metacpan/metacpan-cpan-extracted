package Continuity::Adapt::HttpDaemon;

use strict;
use warnings;  # XXX dev

use Continuity::Request;
use base 'Continuity::Request';

use Continuity::RequestHolder;

use IO::Handle;
use Cwd;

use HTTP::Daemon; 
use HTTP::Status;
use LWP::MediaTypes qw(add_type);

# Accessors

# Hold the HTTP::Daemon object
sub daemon { exists $_[1] ? $_[0]->{daemon} = $_[1] : $_[0]->{daemon} }

# Path for static documents
sub docroot { exists $_[1] ? $_[0]->{docroot} = $_[1] : $_[0]->{docroot} }

# Low-level connection
sub conn { exists $_[1] ? $_[0]->{conn} = $_[1] : $_[0]->{conn} }

# Actual request object
sub http_request { exists $_[1] ? $_[0]->{http_request} = $_[1] : $_[0]->{http_request} }

# Flag, never send type
sub no_content_type { exists $_[1] ? $_[0]->{no_content_type} = $_[1] : $_[0]->{no_content_type} }

sub debug_level { exists $_[1] ? $_[0]->{debug_level} = $_[1] : $_[0]->{debug_level} }

sub debug_callback { exists $_[1] ? $_[0]->{debug_callback} = $_[1] : $_[0]->{debug_callback} }

=head1 NAME

Continuity::Adapt::HttpDaemon - Use HTTP::Daemon to get HTTP requests

Continuity::Adapt::HttpDaemon::Request - an HTTP::Daemon based request

=head1 DESCRIPTION

This is the default and reference HTTP adapter for L<Continuity>. The only
thing a normal user of Continuity would want to do with this is in the C<< new
>> method, all the rest is for internal use. See L<Continuity::Request> for the
general request API used by an application.

An adapter interfaces between the continuation server (L<Continuity>) and the
web server (HTTP::Daemon, FastCGI, etc). It provides incoming HTTP requests to
the continuation server. It comes in two parts, the server connector and the
request interface.

This adapter interfaces with L<HTTP::Daemon>.

This module was designed to be subclassed to fine-tune behavior.

=head1 METHODS

=head2 C<< $adapter = Continuity::Adapt::HttpDaemon->new(...) >>

Create a new continuation adapter and HTTP::Daemon. This actually starts the
HTTP server, which is embeded. It takes the same arguments as the
L<HTTP::Daemon> module, and those arguments are passed along.  It also takes
the optional argument C<< docroot => '/path' >>. This adapter may then be
specified for use with the following code:

  my $server = Contuinity->new(adapter => $adapter);

This method is required for all adapters.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %args = @_;
  my $self = bless { 
    docroot => delete $args{docroot},
    server => delete $args{server},
    no_content_type => delete $args{no_content_type},
    cookies => '',
    debug_level => delete $args{debug_level},
    debug_callback => delete $args{debug_callback},
  }, $class;

  # Set up our http daemon
  $self->daemon(HTTP::Daemon->new(
    ReuseAddr => 1,
    %args,
  )) or die $@;

  $self->docroot(Cwd::getcwd()) if $self->docroot eq '.' or $self->docroot eq './';

  $self->Continuity::debug(1, "Please contact me at: " . $self->daemon->url);

  return $self;
}

=head2 C<< $adapter->get_request() >>

Map a URL path to a filesystem path

Called in a loop from L<Contuinity>.

Returns the empty list on failure, which aborts the server process.
Aside from the constructor, this is the heart of this module.

This method is required for all adapters.

=cut

sub get_request {
  my ($self) = @_;

  # $self->Continuity::debug(2,__FILE__, ' ', __LINE__, "\n");
  while(1) {
    my $c = $self->daemon->accept or next;
    my $r = $c->get_request or next;
    return Continuity::Adapt::HttpDaemon::Request->new(
      debug_level => $self->debug_level,
      debug_callback => $self->debug_callback,
      conn => $c,
      http_request => $r,
      no_content_type => $self->no_content_type,
      cookies => '',
    );
  }
}

=head2 C<< $adapter->map_path($path) >>

Decodes URL-encoding in the path and attempts to guard against malice.
Returns the processed filesystem path.

=cut

sub map_path {
  my $self = shift;
  my $path = shift() || '';
  my $docroot = $self->docroot || '';
  $docroot .= '/' if $docroot and $docroot ne '.' and $docroot !~ m{/$};
  # some massaging, also makes it more secure
  $path =~ s/%([0-9a-fA-F][0-9a-fA-F])/chr hex $1/ge;
  $path =~ s%//+%/%g unless $docroot;
  $path =~ s%/\.(?=/|$)%%g;
  $path =~ s%/[^/]+/\.\.(?=/|$)%%g;

  # if($path =~ m%^/?\.\.(?=/|$)%) then bad

$self->Continuity::debug(2,"path: $docroot$path\n");

  return "$docroot$path";
}

=head2 C<< $adapter->send_static($request) >>

Sends a static file off of the filesystem. The content-type is guessed by
HTTP::Daemon, plus we specifically tell it how to do png, css, and js.

This may be obvious, but you can't send binary data as part of the same request
that you've already sent text or HTML on, MIME aside. Thus either this is
called OR we invoke a continuation, but not both.

=cut

# HTTP::Daemon::send_file_response uses LWP::MediaTypes to guess the
# Content-Type of a file.  Unfortunately, its list of known extensions is
# rather anemic so we're adding a few more.
add_type('image/png'       => qw(png));
add_type('text/css'        => qw(css));
add_type('text/javascript' => qw(js));

sub send_static {
  my ($self, $r) = @_;
  my $c = $r->conn or die;
  my $url = $r->url;
  $url =~ s{\?.*}{};
  my $path = $self->map_path($url) or do { 
       $self->Continuity::debug(1, "can't map path: " . $url); $c->send_error(404); return; 
  };
  unless (-f $path) {
      $c->send_error(404);
      return;
  }
  $c->send_file_response($path);
  $self->Continuity::debug(3, "Static send '$path'");
}

package Continuity::Adapt::HttpDaemon::Request;

# Accessors

# List of cookies to send
sub cookies { exists $_[1] ? $_[0]->{cookies} = $_[1] : $_[0]->{cookies} }

# The actual connection
sub conn { exists $_[1] ? $_[0]->{conn} = $_[1] : $_[0]->{conn} }

# The HTTP::Request object
sub http_request { exists $_[1] ? $_[0]->{http_request} = $_[1] : $_[0]->{http_request} }

# Watch for writes to the conn
sub write_event { exists $_[1] ? $_[0]->{write_event} = $_[1] : $_[0]->{write_event} }

# Flag, never send type
sub no_content_type { exists $_[1] ? $_[0]->{no_content_type} = $_[1] : $_[0]->{no_content_type} }

# CGI query params
sub cached_params { exists $_[1] ? $_[0]->{cached_params} = $_[1] : $_[0]->{cached_params} }

sub debug_level { exists $_[1] ? $_[0]->{debug_level} = $_[1] : $_[0]->{debug_level} }

sub debug_callback { exists $_[1] ? $_[0]->{debug_callback} = $_[1] : $_[0]->{debug_callback} }

=for comment

See L<Continuity::Request> for API documentation.

This is what gets passed through a queue to coroutines when new requests for
them come in. It needs to encapsulate:

*  The connection filehandle
*  CGI parameters cache

XXX todo: understands GET parameters and POST in
application/x-www-form-urlencoded format, but not POST data in
multipart/form-data format.  Use the AsCGI thing if you actually really need
that (it's used for file uploads).
# XXX check request content-type, if it isn't x-form-data then throw an error
# XXX pass in multiple param names, get back multiple param values

Delegates requests off to the request object it was initialized from.

In other words: Continuity::Adapt::HttpDaemon is the ongoing running HttpDaemon
process, and Continuity::Adapt::HttpDaemon::Request is individual requests sent
through.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless { @_ }, $class;
    eval { $self->conn->isa('HTTP::Daemon::ClientConn') } or warn "\$self->conn isn't an HTTP::Daemon::ClientConn";
    eval { $self->http_request->isa('HTTP::Request') } or warn "\$self->http_request isn't an HTTP::Request";
    $self->Continuity::debug(2, "\n====== Got new request ======\n"
               . "       Conn: ".$self->conn."\n"
               . "    Request: $self"
    );
    return $self;
}

sub param {
    my $self = shift; 
    my $req = $self->http_request;
    unless($self->cached_params) {
      $self->cached_params( do {
        my $in = $req->uri; $in .= '&' . $req->content if $req->content;
        $in =~ s{^.*\?}{};
        my @params;
        for(split/[&]/, $in) { 
            tr/+/ /; 
            s{%(..)}{pack('c',hex($1))}ge; 
            my($k, $v); ($k, $v) = m/(.*?)=(.*)/s or ($k, $v) = ($_, 1);
            push @params, $k, $v; 
        };
        \@params;
      });
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

sub url_path {
  my $self = shift;
  my $path = $self->url->path;
  return $path;
}

sub end_request {
    my $self = shift;
    $self->write_event->cancel if $self->write_event;
    $self->conn->close if $self->conn;
}

sub set_cookie {
    my $self = shift;
    my $cookie = shift;
    # record cookies and then send them the next time send_basic_header() is called and a header is sent.
    $self->cookies($self->cookies . "Set-Cookie: $cookie\r\n");
}

sub get_cookie {
    my $self = shift;
    my $cookie_name = shift;
    my ($cookie) =  map $_->[1],
      grep $_->[0] eq $cookie_name,
      map [ m/(.*?)=(.*)/ ],
      split /; */,
      $self->headers->header('Cookie') || '';
    return $cookie;
}

sub send_basic_header {
    my $self = shift;
    my $cookies = $self->cookies;
    $self->cookies('');
    $self->conn->send_basic_header;  # perhaps another flag should cover sending this, but it shouldn't be called "no_content_type"
    unless($self->no_content_type) {
      $self->print(
           "Cache-Control: private, no-store, no-cache\r\n",
           "Pragma: no-cache\r\n",
           "Expires: 0\r\n",
           "Content-type: text/html\r\n",
           $cookies,
           "\r\n"
      );
    }
    1;
}

sub print { 
    my $self = shift; 
    $self->write_event(Coro::Event->io(fd => fileno $self->conn, poll => 'w', )) unless $self->write_event;
    my $e = $self->write_event;
    if(length $_[0] > 4096) {
        while(@_) { 
            my $x = shift;
            while(length $x > 4096) { $e->next; $self->conn->print(substr $x, 0, 4096, ''); }
            $e->next; $self->conn->print($x) 
        }
    } else {
        $e->next; $self->conn->print(@_); 
    }
    Coro::cede();
    return 1;
}

sub uri { $_[0]->http_request->uri(); }

sub method { $_[0]->http_request->method(); }

#
# end public Continuity::Request API methods
#

# sub query_string { $_[0]->{http_request}->query_string(); } # nope, doesn't exist in HTTP::Headers

sub immediate { }


# If we don't know how to do something, pass it on to the current http_request

sub AUTOLOAD {
  our $AUTOLOAD;
  my $method = $AUTOLOAD; $method =~ s/.*:://;
  return if $method eq 'DESTROY';
  my $self = shift;
  my $retval;
  if({peerhost=>1,send_basic_header=>1,'print'=>1,'send_redirect'=>1}->{$method}) {
    $retval = eval { $self->conn->$method(@_) };
    if($@) {
      warn "Continuity::Adapt::HttpDaemon::Request::AUTOLOAD: "
         . "Error calling conn method ``$method'', $@";
    }
  } else {
    $retval = eval { $self->http_request->$method(@_) };
    if($@) {
      warn "Continuity::Adapt::HttpDaemon::Request::AUTOLOAD: "
         . "Error calling HTTP::Request method ``$method'', $@";
    }
  }
  return $retval;
}

=head1 HTTP::Daemon Overrides

Although HTTP::Daemon is lovely, we have to patch it a bit to work correctly
with Coro. Fortunately there are only two things that much be touched, the
'accept' method and the _needs_more_data in HTTP::Daemon::ClientConn.

What we are doing is making these non-blocking using Coro::Event.

=cut

do {

    # HTTP::Daemon isn't Coro-friendly and attempting to diddle HTTP::Daemon's
    # inheritance to use Coro::Socket instead was a disaster.  So, instead, we
    # provide reimplementations of just a couple of functions to make it all
    # Coro-friendly.  This kind of meddling- under-the-hood is still just
    # asking for breaking from future versions of HTTP::Daemon.

    package HTTP::Daemon;
    use Errno;
    use Fcntl uc ':default';

    no warnings; # Don't warn for this override (this should be narrowed)
    sub accept {
        my $self = shift;
        my $pkg = shift || "HTTP::Daemon::ClientConn";  
        fcntl $self, &Fcntl::F_SETFL, &Fcntl::O_NONBLOCK or die "fcntl(O_NONBLOCK): $!";
        try_again:
        my ($sock, $peer) = $self->SUPER::accept($pkg);
        if($sock) {
            ${*$sock}{'httpd_daemon'} = $self;
            return wantarray ? ($sock, $peer) : $sock;
        } elsif($!{EAGAIN}) {
            my $socket_read_event = Coro::Event->io(fd => fileno $self, poll => 'r', ); # XXX should create this once per call rather than once per EGAIN
            $socket_read_event->next;
            $socket_read_event->cancel;
            goto try_again; 
        } else {
            return;
        }
    }

    package HTTP::Daemon::ClientConn;

    no warnings; # Don't warn for this override (this should be narrowed)

    sub _need_more {   
        my $self = shift;
        my $e = Coro::Event->io(fd => fileno $self, poll => 'r', $_[1] ? ( timeout => $_[1] ) : ( ), );
        $e->next;
        $e->cancel;
        my $n = sysread($self, $_[0], 2048, length($_[0]));
        $self->reason(defined($n) ? "Client closed" : "sysread: $!") unless $n;
        $n;
    }   

};

=head1 SEE ALSO

L<Continuity>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/
  Scott Walters <scott@slowass.net> - http://slowass.net/

=head1 COPYRIGHT

  Copyright (c) 2004-2014 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

1;

