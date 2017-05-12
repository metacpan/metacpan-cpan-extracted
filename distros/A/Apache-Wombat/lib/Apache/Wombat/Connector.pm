# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Apache::Wombat::Connector;

=pod

=head1 NAME

Apache::Wombat::Connector - Apache/mod_perl connector

=head1 SYNOPSIS

  # My/Handler.pm

  my $connector = Apache::Wombat::Connector->new();
  $connector->setName('Apache connector');
  $connector->setScheme('http');
  $connector->setSecure(undef)

  # ... create a Service as $service
  # calls $connector->setContainer() internally
  $service->addConnector($connector);

  sub child_init_handler {
      my $r = shift;
      $connector->start();
      return Apache::Constants::OK;
  }

  sub handler {
      my $r = shift;
      $connector->process($r);
      return $r->status();
  }

  sub child_exit_handler {
      my $r = shift;
      $connector->stop();
      return Apache::Constants::OK;
  }

  # httpd.conf:
  <Location />
    SetHandler perl-script
    PerlChildInitHandler My::Handler::child_init_handler
    PerlHandler          My::Handler::handler
    PerlChildExitHandler My::Handler::child_exit_handler
  </Location>

=head1 DESCRIPTION

This Connector receives requests from and returns responses to an
Apache web server within which Wombat is embedded. It does not listen
on a socket but rather provides a C<process()> entry point with which
it receives and returns an B<Apache> instance. It provides HttpRequest
and HttpResponse implementations that delegate many fields and methods
to an underlying B<Apache::Request> instance.

ApacheConnector assumes an Apache 1 & mod_perl 1 single-threaded
multi-process environment. It's unknown whether it will work in any
other environment.

Requires mod_perl to be compiled with at least one of the following
options:

  DYNAMIC=1
  PERL_TABLE_API=1
  EVERYTHING=1

=cut

use base qw(Wombat::Connector);
use fields qw(container scheme secure serverHeader started);
use strict;
use warnings;

use Apache::Request ();
use Servlet::Util::Exception ();
use Apache::Wombat::Request ();
use Apache::Wombat::Response ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Create and return an instance, initializing fields to default values.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{container} = undef;
    $self->{secure} = undef;
    $self->{scheme} = 'http';
    $self->{serverHeader} = undef;
    $self->{started} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container used for processing Requests received by this
Connector.

=cut

sub getContainer {
    my $self = shift;

    return $self->{container};
}

=pod

=item setContainer($container)

Set the Container used for processing Requests received by this
Connector.

B<Parameters:>

=over

=item $container

the B<Wombat::Container> used for processing Requests

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    $self->{container} = $container;

    return 1;
}

=pod

=item getName()

Return the display name of this Connector.

=cut

sub getName {
    my $self = shift;

    return "Apache/mod_perl Connector";
}

=pod

=item getScheme()

Return the scheme that will be assigned to Requests recieved through
this Connector. Default value is I<http>.

=cut

sub getScheme {
    my $self = shift;

    return $self->{scheme};
}

=pod

=item setScheme($scheme)

Set the scheme that will be assigned to Requests received through this
Connector.

B<Parameters:>

=over

=item $scheme

the scheme

=back

=cut

sub setScheme {
    my $self = shift;
    my $scheme = shift;

    $self->{scheme} = $scheme;

    return 1;
}

=pod

=item getSecure()

Return the secure connection flag that will be assigned to Requests
received through this Connector. Default value is false.

=cut

sub getSecure {
    my $self = shift;

    return $self->{secure};
}

=pod

=item setSecure($secure)

Set the secure connection flag that will be assigned to Requests
received through this Connector.

B<Parameters:>

=over

=item $secure

the boolean secure connection flag

=back

=cut

sub setSecure {
    my $self = shift;
    my $secure = shift;

    $self->{secure} = $secure;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item await()

Begin listening for requests. Returns immediately since Apache itself
listens for requests.

=cut

sub await {
    my $self = shift;

    return 1;
}

=pod

=item createRequest()

Create and return a B<Apache::Wombat::Request>
instance.

=cut

sub createRequest {
    my $self = shift;

    return Apache::Wombat::Request->new();
}

=pod

=item createResponse()

Create and return a B<Apache::Wombat::Response>
instance.

=cut

sub createResponse {
    my $self = shift;

    return Apache::Wombat::Response->new();
}

=pod

=item process($r)

Process the given Apache request record (converting it to an instance
of B<Apache::Request> in the process), generating and sending a
response. This method is meant to be called during the content
handling phase by a PerlHandler subroutine; after calling this method,
the handler should examine the Apache request's status code and return
an appropriate value.

B<Parameters:>

=over

=item $r

the B<Apache> instance

=back

=cut

sub process {
    my $self = shift;
    my $r = shift;

    # 1. receive request
    my $apr = Apache::Request->instance($r, DISABLE_UPLOADS => 1);
#
    # 2. create Request and Response instances
    my $request = $self->createRequest();
    $request->setRequestRec($apr);

    my $response = $self->createResponse();
    $response->setRequestRec($apr);

    # 2.1 set Request fields
    $request->setConnector($self);
    $request->setContentLength($apr->header_in('Content-Length'));
    $request->setContentType($apr->header_in('Content-Type'));
    $request->setHandle($apr);
    # protocol handled by $apr
    # remoteAddr handled by $apr
    $request->setResponse($response);
    $request->setScheme($self->getScheme());
    $request->setSecure($self->getSecure());
    $request->setServerName($apr->hostname());
    $request->setServerPort($apr->get_server_port());
    $request->setSocket($apr);

    # 2.2 set HttpRequest fields
    # method handled by $apr
    # queryString handled by $apr

    # requestURI and maybe session ID stuff
    my $uri = $apr->uri();
    my $sessionID = Wombat::Util::RequestUtil->decodeURI(\$uri);
    $request->setRequestURI($uri);
    if ($sessionID) {
        $request->setRequestedSessionId($sessionID);
        $request->setRequestedSessionCookie(undef);
        $request->setRequestedSessionURL(1);
    }

    # locales
    my $acceptLangHdr = $apr->header_in('Accept-Language');
    for my $locale (Wombat::Util::RequestUtil->parseLocales($acceptLangHdr)) {
        $request->addLocale($locale);
    }

    # cookies and maybe session ID stuff
    my $cookieHdr = $apr->header_in('Cookie');
    for my $cookie (Wombat::Util::RequestUtil->parseCookies($cookieHdr)) {
        if ($cookie->getName() eq Wombat::Globals::SESSION_COOKIE_NAME) {
            # override session id specified in URI
            $request->setRequestedSessionId($cookie->getValue());
            $request->setRequestedSessionCookie(1);
            $request->setRequestedSessionURL(undef);

            # don't add session cookie
            next;
        }

        $request->addCookie($cookie);
    }

    # headers
    my $headers = $apr->headers_in();
    while (my ($key, $val) = each %$headers) {
        $request->addHeader($key, $val);
    }

    # security-related fields
    $request->setAuthorization($apr->header_in('Authorization'));

    # 2.3 Response fields
    $response->setConnector($self);
    $response->setHandle($apr);
    $response->setRequest($request);

    # 2.4 HttpResponse fields

    # 3 identify container
    my $container = $self->getContainer();
    # XXX: use Host header and $apr->location() to find an Application?

    # 4+5 call invoke and return response
    eval {
        $container->invoke($request, $response);
    };
    if ($@) {
        $self->log('error invoking container', $@, 'ERROR');

        my $status =
            Servlet::Http::HttpServletResponse::SC_INTERNAL_SERVER_ERROR;
        $response->sendError($status);
        $container->handleError($request, $response, $@);
    }

    eval {
        $response->finishResponse();
        $request->finishRequest();
    };
    if ($@) {
        $self->log("error finishing up", $@, 'ERROR');
    }

    return 1;
}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this component. This method should be called
before any of the public methods of the component are utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the component has already been started

=back

=cut

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: connector already started";
        Wombat::LifecycleException->throw($msg);
    }

    $self->{started} = 1;
    $self->log(sprintf("%s started", $self->getName()), undef, 'INFO');

    return 1;
}

=pod

=item stop()

Gracefully terminate active use of this component. Once this method
has been called, no public methods of the component should be
utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the component is not started

=back

=cut

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        my $msg = "stop: connector not started";
        Wombat::LifecycleException->throw($msg);
    }

    undef $self->{started};
    $self->debug(sprintf("%s stopped", $self->getName()));

    return 1;
}

# private methods

sub debug {
    my $self = shift;
    my $msg = shift;

    Wombat::Globals::DEBUG and
        $self->log($msg, undef, 'DEBUG');

    return 1;
}

sub log {
    my $self = shift;
    my $error = shift || '';

    if ($self->{container}) {
        $self->{container}->log(sprintf("ApacheConnector[%s]: %s",
                                        $self->getName(), $error), @_);
    }

    return 1;
  }

1;
__END__

=pod

=back

=head1 SEE ALSO

L<mod_perl>,
L<Apache>,
L<Apache::Request>,
L<Wombat::Container>,
L<Apache::Wombat::Request>,
L<Apache::Wombat::Response>,
L<Wombat::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
