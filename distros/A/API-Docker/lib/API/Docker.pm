package API::Docker;
# ABSTRACT: Perl client for the Docker Engine API
our $VERSION = '0.006';
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

use API::Docker::API::System;
use API::Docker::API::Containers;
use API::Docker::API::Images;
use API::Docker::API::Networks;
use API::Docker::API::Volumes;
use API::Docker::API::Exec;
use API::Docker::API::Distribution;
use API::Docker::API::Secrets;
use API::Docker::API::Configs;
use API::Docker::API::Plugins;
use namespace::clean;


has host => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_HOST} // 'unix:///var/run/docker.sock' },
);


has api_version => (
  is      => 'rwp',
  default => undef,
);


has tls => (
  is => 'lazy',
);

sub _build_tls {
  my ($self) = @_;

  # The docker CLI's own rule, read off cli/flags/options.go:
  #   dockerTLSVerify = os.Getenv(client.EnvTLSVerify) != ""
  # Every non-empty value turns TLS on, DOCKER_TLS_VERIFY=0 included. Perl
  # truthiness would read that '0' as off and disagree with the CLI on exactly
  # the value a user is most likely to type for "off", so the test is
  # defined-and-not-empty rather than a boolean one.
  return 0 unless defined $ENV{DOCKER_TLS_VERIFY}
    && $ENV{DOCKER_TLS_VERIFY} ne '';

  # And the CLI ignores TLS on a socket host without saying so
  # (cli/context/docker/load.go, "there's no need to configure TLS for a
  # socket connection"). Ignoring it here is not politeness: BUILD croaks on
  # tls => 1 with a non-tcp:// host, so a host-blind default would make a bare
  # API::Docker->new die on every unix:// machine that exports the variable.
  return $self->host =~ m{^tcp://} ? 1 : 0;
}


has cert_path => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_CERT_PATH} },
);


has tls_insecure => (
  is      => 'ro',
  default => 0,
);


sub BUILD {
  my ($self) = @_;

  # Both checks are here rather than at connect time so that a request for
  # encryption that cannot be honoured is refused before the caller has a
  # client to hand credentials to.
  croak __PACKAGE__ . '->new tls_insecure => 1 without tls => 1 does '
    . 'nothing: verification is only reachable on a connection that has TLS '
    . 'to verify. Set tls => 1 as well, or drop the option'
    if $self->tls_insecure && !$self->tls;

  return unless $self->tls;

  my $host = $self->host;
  croak __PACKAGE__ . '->new tls => 1 is only meaningful for a tcp:// host, '
    . 'and this one is ' . $host . '. A Unix socket is a file rather than a '
    . 'wire and carries nothing to encrypt, so honouring the option is not '
    . 'possible and ignoring it would answer a request for an encrypted '
    . 'transport with an unencrypted one'
    unless $host =~ m{^tcp://};
}

has _version_negotiated => (
  is      => 'rw',
  default => 0,
);

with 'API::Docker::Role::HTTP';

has system => (
  is      => 'lazy',
  builder => sub { API::Docker::API::System->new(client => $_[0]) },
);


has containers => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Containers->new(client => $_[0]) },
);


has images => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Images->new(client => $_[0]) },
);


has networks => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Networks->new(client => $_[0]) },
);


has volumes => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Volumes->new(client => $_[0]) },
);


has exec => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Exec->new(client => $_[0]) },
);


has distribution => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Distribution->new(client => $_[0]) },
);


has secrets => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Secrets->new(client => $_[0]) },
);


has configs => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Configs->new(client => $_[0]) },
);


has plugins => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Plugins->new(client => $_[0]) },
);


sub negotiate_version {
  my ($self, %opts) = @_;
  return if $self->_version_negotiated;
  return if defined $self->api_version;

  $log->debug("Auto-negotiating API version");
  my $version_info = $self->_request('GET', '/version',
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
  );

  # The ApiVersion is put straight into every later request path (/v1.44/...),
  # so it has to be a JSON object carrying one of the form N.N -- nothing else
  # can be trusted there. Three ways a body fails that, each measured against a
  # fake daemon: a non-object body reached strict refs ('garbage' died with
  # "Can't use string as a HASH ref", [1] with "Not a HASH reference"); an
  # object with no ApiVersion set _version_negotiated and then sent every
  # request unversioned; and an ApiVersion copied verbatim let 'v1.44/../x'
  # become "GET /vv1.44/../x/info". One croak, naming the endpoint and the
  # shape, covers all of them.
  my $got;
  if (!defined $version_info) {
    $got = 'nothing';
  }
  elsif (ref $version_info ne 'HASH') {
    $got = ref $version_info ? 'a ' . ref($version_info) . ' reference'
      : "the non-object body '" . $version_info . "'";
  }
  elsif (!defined $version_info->{ApiVersion}) {
    $got = 'an object with no ApiVersion field';
  }
  else {
    my $v = $version_info->{ApiVersion};
    $got = 'an ApiVersion of '
      . (ref $v ? 'a ' . ref($v) . ' reference' : "'" . $v . "'");
  }

  croak __PACKAGE__ . '->negotiate_version: GET /version must answer with a '
    . 'JSON object carrying an ApiVersion of the form N.N (e.g. "1.44"); got '
    . $got
    unless ref $version_info eq 'HASH'
      && defined $version_info->{ApiVersion}
      && !ref $version_info->{ApiVersion}
      && $version_info->{ApiVersion} =~ /^\d+\.\d+$/;

  $self->_set_api_version($version_info->{ApiVersion});
  $log->debugf("Negotiated API version: %s", $version_info->{ApiVersion});
  $self->_version_negotiated(1);
}


around _request => sub {
  my ($orig, $self, $method, $path, %opts) = @_;

  # Auto-negotiate before any versioned request, but not for /version itself.
  # The triggering request's own bounds are handed to it: the negotiation is a
  # pre-flight the caller never wrote, and a caller who asked for a bound and
  # then hung in GET /version has been told something untrue (karr k72).
  if ($path ne '/version' && !defined $self->api_version && !$self->_version_negotiated) {
    $self->negotiate_version(
      exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
      exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
    );
  }

  return $self->$orig($method, $path, %opts);
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker - Perl client for the Docker Engine API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use API::Docker;

    # Connect to local Docker daemon via Unix socket
    my $docker = API::Docker->new;

    # Or connect to remote Docker daemon
    my $docker = API::Docker->new(
        host => 'tcp://192.168.1.100:2375',
    );

    # System information
    my $info = $docker->system->info;
    my $version = $docker->system->version;

    # Container management -- list/inspect return generated
    # API::Docker::Type::* objects with snake_case accessors, not hashrefs
    my $containers = $docker->containers->list(all => 1);
    for my $container (@$containers) {
        say $container->id;
        say $container->status;
    }

    my $result = $docker->containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
    );
    $docker->containers->start($result->{Id});

    my $inspected = $docker->containers->inspect($result->{Id});
    say $inspected->state->running ? 'running' : 'not running';

    # Image operations
    $docker->images->pull(fromImage => 'nginx', tag => 'latest');
    my $images = $docker->images->list;

    # Network and volume management
    my $networks = $docker->networks->list;
    my $volumes = $docker->volumes->list;

=head1 DESCRIPTION

API::Docker is a Perl client for the Docker Engine API. It provides a clean
object-oriented interface to manage Docker containers, images, networks, and
volumes.

Key features:

=over

=item * Pure Perl implementation with minimal dependencies

=item * Unix socket and TCP transport, the latter in the clear or over TLS
with client certificates (L</tls>, L</cert_path>)

=item * Automatic API version negotiation

=item * A typed object model generated from Docker's own swagger
(L<API::Docker::Type>) -- complete across all seven resources: C<list> and
C<inspect> return these generated classes, not hashrefs; see
L</Architecture> below

=item * Comprehensive logging via L<Log::Any>

=back

=head2 Architecture

The distribution is organized into several layers:

=over

=item * B<Main Client> - L<API::Docker> - Entry point with API version negotiation

=item * B<API Modules> - Resource-specific API methods:

=over

=item * L<API::Docker::API::System> - System info, version, ping

=item * L<API::Docker::API::Containers> - Container management

=item * L<API::Docker::API::Images> - Image management

=item * L<API::Docker::API::Networks> - Network management

=item * L<API::Docker::API::Volumes> - Volume management

=item * L<API::Docker::API::Exec> - Exec into containers

=item * L<API::Docker::API::Distribution> - Registry manifest lookups

=item * L<API::Docker::API::Secrets> - Swarm secrets

=item * L<API::Docker::API::Configs> - Swarm configs

=item * L<API::Docker::API::Plugins> - Managed plugins

=back

=item * B<Entity Roles> - the convenience methods of a resource, composed at
load time onto the generated L<API::Docker::Type> classes its endpoints
answer with. There is no separate wrapper object: C<< $docker->images->list >>
hands back real L<API::Docker::Type::ImageSummary> objects that also have
C<< ->remove >>. See L<API::Docker::Role::Entity>.

=over

=item * L<API::Docker::Role::Entity::Container> - composed into
L<API::Docker::Type::ContainerSummary> and
L<API::Docker::Type::ContainerInspectResponse>

=item * L<API::Docker::Role::Entity::Image> - composed into
L<API::Docker::Type::ImageSummary> and L<API::Docker::Type::ImageInspect>

=item * L<API::Docker::Role::Entity::Network> - composed into
L<API::Docker::Type::Network>, which serves both C<list> and C<inspect>

=item * L<API::Docker::Role::Entity::Volume> - composed into
L<API::Docker::Type::Volume>, which serves C<list>, C<inspect> and C<create>

=item * L<API::Docker::Role::Entity::Secret> - composed into
L<API::Docker::Type::Secret>

=item * L<API::Docker::Role::Entity::Config> - composed into
L<API::Docker::Type::Config>

=item * L<API::Docker::Role::Entity::Plugin> - composed into
L<API::Docker::Type::Plugin>

=back

=item * B<Roles> - Behaviour shared across more than one class:

=over

=item * L<API::Docker::Role::HTTP> - HTTP transport layer

=item * L<API::Docker::Role::RegistryAuth> - X-Registry-Auth / AuthConfig
encoding, shared by Images, Plugins, Distribution and System

=item * L<API::Docker::Role::Filters> - the C<filters> query parameter,
normalised into the one shape the engine reads

=item * L<API::Docker::Role::Using> - C<using>, the resource class clone that
bounds a run of calls

=item * L<API::Docker::Role::Type> - the instance behaviour of every
generated L<API::Docker::Type> class: serialisation both ways and
C<unknown_fields>

=item * L<API::Docker::Role::Entity> - the client reference an entity
delegates through, composed by a resource-specific entity role such as
L<API::Docker::Role::Entity::Container>

=back

=back

=head2 Swarm orchestration is out of scope

C</swarm>, C</nodes>, C</services> and C</tasks> are deliberately absent, and
staying absent is the plan rather than a gap waiting to be closed. That is a
scope decision: Swarm sees too little practical use to be worth the surface,
Podman -- the engine this distribution is actually tested against --
implements none of the Swarm family at all, and no consumer of this
distribution has asked for it. Docker has not withdrawn Swarm, and nothing
here claims it has; this distribution simply chooses not to follow it.

What already works without Swarm keeps working. L<API::Docker::API::Secrets>
and L<API::Docker::API::Configs> are covered despite belonging to that same
Engine API family, because both stand on their own rather than on an
orchestrator -- see
L<API::Docker::API::Secrets/"Swarm, and what Podman serves instead"> for what
that looks like against each engine, Docker's single-node 503 included.
Anyone who actually needs Swarm orchestration should reach for a client built
around it; extending this one to cover it is not on the roadmap.

=head2 host

Docker daemon connection URL. Defaults to C<$ENV{DOCKER_HOST}> or
C<unix:///var/run/docker.sock>.

No other source is consulted; see L</Socket discovery>.

Supported formats:

=over

=item * C<unix:///path/to/socket> - Unix socket (default)

=item * C<tcp://host:port> - TCP connection

=back

=head2 api_version

Docker API version to use (e.g., C<1.41>). If not set, the client will
automatically negotiate the highest API version supported by the daemon.

This attribute is set automatically by L</negotiate_version>.

=head2 tls

Speak TLS on a C<tcp://> connection. Defaults to C<1> when
C<$ENV{DOCKER_TLS_VERIFY}> holds any non-empty value and L</host> is a
C<tcp://> one, and to C<0> -- plaintext -- otherwise.

    my $docker = API::Docker->new(
      host      => 'tcp://dockerhost:2376',
      tls       => 1,
      cert_path => '/home/me/.docker',
    );

The default follows the C<docker> CLI rather than the Go SDK's C<FromEnv>: the
CLI reads the variable as C<< != "" >>, so B<every non-empty value turns TLS
on> -- C<DOCKER_TLS_VERIFY=0> included, and so are C<false>, C<no> and C<off>.
Only unset, or the empty string, is off. That is deliberately not Perl
truthiness: C<'0'> is the value most likely to be typed for "off" and is
precisely where the two rules would part company. An explicit C<< tls => ... >>
passed to the constructor outranks the variable in both directions.

The variable is B<ignored on a socket host>, as the CLI ignores it -- a
C<unix://>, C<npipe://> or C<fd://> connection carries nothing to encrypt.
Without that exception a shell exporting C<DOCKER_TLS_VERIFY> would make a bare
C<< API::Docker->new >> croak on every machine talking to a local socket, since
C<< tls => 1 >> on a non-C<tcp://> host is a construction error (below).

C<DOCKER_TLS_VERIFY> with no L</cert_path> and no C<DOCKER_CERT_PATH> beside it
is TLS against the system trust store, not an error; the CLI asks for no
certificates either, and non-empty there means encrypt B<and> verify.

With C<< tls => 1 >> the transport opens an L<IO::Socket::SSL> connection
instead of an L<IO::Socket::INET> one and nothing above the socket changes.
The daemon's certificate is B<verified>, and so is its hostname; L</cert_path>
supplies the trust anchor and this client's own certificate.

With no certificates at all it still means encrypt and verify, against the
system trust store -- see
L<API::Docker::Role::HTTP/"TLS with no certificates at all">
for why that rather than an error. To switch verification off, and to read
what that gives away, see L</tls_insecure>.

C<< tls => 1 >> on a C<unix://> host croaks at construction. A Unix socket is
a file, not a wire; there is nothing on it to encrypt, and accepting the
option would mean answering a request for an encrypted transport with an
unencrypted one -- which is the failure this attribute previously had.

L<IO::Socket::SSL> is a recommended rather than a required dependency, loaded
when the first TLS connection is opened; C<< tls => 1 >> without it installed
croaks naming it. See
L<API::Docker::Role::HTTP/"TLS on a tcp:// connection"> for the whole of the
policy.

=head2 cert_path

Directory holding the TLS certificates, in the layout the C<docker> CLI
writes: F<ca.pem> as the trust anchor, F<cert.pem> and F<key.pem> as this
client's certificate and key. Defaults to C<$ENV{DOCKER_CERT_PATH}>.

Each file is used if it is there. F<ca.pem> alone is a daemon this client
verifies but does not authenticate to; F<cert.pem> without F<key.pem> or the
reverse is a croak, since half a client certificate is an accident rather than
a mode. A C<cert_path> naming something that is not a directory croaks too.

B<Read only when L</tls> is set.> The default comes from the environment, and
C<DOCKER_CERT_PATH> is exported on plenty of machines that run the C<docker>
CLI, so a client that never asked for TLS is unaffected by having it set. A
TLS client that wants the system trust store rather than the CLI's private one
on such a machine passes C<< cert_path => undef >> explicitly.

=head2 tls_insecure

Turn certificate verification off. Default C<0>. Only read when L</tls> is
set, and named for what it does.

C<< tls_insecure => 1 >> sets C<SSL_VERIFY_NONE> and drops the hostname check,
which leaves a connection encrypted against a passive listener and against
nothing else: whoever answers it chooses the certificate, so anyone able to
redirect the connection reads and rewrites everything on it -- registry
credentials, image contents, the commands containers are started with.

It exists for a self-signed daemon certificate whose CA is not to hand. The
better answer is nearly always L</cert_path>: a self-signed certificate is its
own CA and works as F<ca.pem> directly.

Setting it without L</tls> croaks, rather than being accepted and doing
nothing.

=head2 system

Returns L<API::Docker::API::System> instance for system operations like
C<info>, C<version>, C<ping>, and C<events>.

=head2 containers

Returns L<API::Docker::API::Containers> instance for container operations like
C<list>, C<create>, C<start>, C<stop>, and C<remove>.

=head2 images

Returns L<API::Docker::API::Images> instance for image operations like
C<list>, C<pull>, C<push>, and C<remove>.

=head2 networks

Returns L<API::Docker::API::Networks> instance for network operations like
C<list>, C<create>, C<connect>, and C<disconnect>.

=head2 volumes

Returns L<API::Docker::API::Volumes> instance for volume operations like
C<list>, C<create>, and C<remove>.

=head2 exec

Returns L<API::Docker::API::Exec> instance for executing commands in containers.

=head2 distribution

Returns L<API::Docker::API::Distribution> instance for registry manifest
lookups: C<inspect> and C<exists>.

=head2 secrets

Returns L<API::Docker::API::Secrets> instance for secret operations: C<list>,
C<create>, C<inspect>, C<update> and C<remove>.

=head2 configs

Returns L<API::Docker::API::Configs> instance for config operations: C<list>,
C<create>, C<inspect>, C<update> and C<remove>.

=head2 plugins

Returns L<API::Docker::API::Plugins> instance for managed-plugin operations:
C<list>, C<privileges>, C<install>, C<inspect>, C<remove>, C<enable>,
C<disable>, C<upgrade>, C<push> and C<configure>.

=head2 negotiate_version

    $docker->negotiate_version;
    $docker->negotiate_version(read_timeout => 5, connect_timeout => 2);

Automatically negotiate the highest API version supported by the Docker daemon.
This is called automatically before the first API request if L</api_version>
is not set.

After negotiation, L</api_version> will contain the negotiated version
(e.g., C<1.41>).

C<GET /version> must answer with a JSON object carrying an C<ApiVersion> of
the form C<N.N> -- the value is placed directly into the path of every later
request (C</v1.44/...>). A body that is not such an object croaks, naming the
endpoint and the shape expected: a non-object body, an object with no
C<ApiVersion>, or an C<ApiVersion> that is not two dot-separated numbers. This
replaces three earlier failures on the same path -- a non-object body dying in
C<strict refs>, an object with no C<ApiVersion> silently leaving the client
sending every request unversioned, and a malformed C<ApiVersion> being copied
verbatim into the request path.

Options:

=over

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

Called on its own, with no options, the negotiation is bounded by the
L<API::Docker::Role::HTTP/read_timeout> and
L<API::Docker::Role::HTTP/connect_timeout> attributes of the client, like any
other request. Reached the way it normally is -- automatically, from the first
request -- it inherits that request's own bounds instead; see
L</"What a timeout covers">.

=head1 TIMEOUTS

=head2 What a timeout covers

Two bounds, covering different halves of a request.
L<API::Docker::Role::HTTP/connect_timeout> bounds opening the connection;
L<API::Docker::Role::HTTP/read_timeout> bounds reading the answer. Both are
attributes of the client, and they are set in two places -- which are two
levels, not two spellings of one thing:

    # the rule, for this client
    my $docker = API::Docker->new(connect_timeout => 2, read_timeout => 30);

    # the exception, for this run of calls
    $docker->containers->using(read_timeout => 5)->list;
    $docker->system->using(read_timeout => 0)->events;

L<API::Docker::Role::Using/using> returns a clone of the resource class
carrying the bounds, and every request made through that clone is given them.
There is deliberately no third way: the individual methods take no timeout
options, so their arguments are the request and nothing else.

Both are off by default, which is the behaviour this distribution has always
had. C<0> means the same as unset -- no bound -- and is how a client-wide
default is turned off for a run of calls: what C<using> carries is read with
C<exists> rather than for truth, so a C<0> reaches the transport instead of
vanishing into "no opinion".

Three things they do not do:

=over

=item * B<C<read_timeout> is an idle timeout, not a deadline.> The clock
measures the time since the last byte arrived, not the time since the request
started. A stream that keeps producing runs as long as it likes; one that
stops producing is cut off. So it bounds a daemon that goes quiet -- it does
not bound a long transfer, and it does not bound a stream that keeps sending
without saying anything, which is what C<< containers->stats >> degrades into
on Docker after the container exits.

=item * B<Neither of them bounds writing the request.> Sending the bytes out
is unbounded on every transport. In practice that matters for one thing: a
large C</build> context or C<< images->load >> archive being written to a
daemon that has stopped reading.

=item * B<Under TLS, C<read_timeout> is not quite an idle timer on the
plaintext.> It is C<SO_RCVTIMEO> on the socket, which bounds each blocking
receive on the underlying connection, and one plaintext read can consume
several of those while a TLS record arrives in pieces -- so a record dribbling
in slowly enough resets the clock without a byte reaching the caller. It still
bounds the hang, which is what it is for. C<connect_timeout> over TLS bounds
the TCP connect and not the handshake that follows it.

=back

An expiry croaks with an L<API::Docker::Error::Timeout> carrying what did
arrive; it never returns a truncated response.
L<API::Docker::Role::HTTP/"Bounding a request that never ends"> and
L<API::Docker::Role::HTTP/"Bounding the connection itself"> have the
per-transport measurements behind all of this.

=head2 Where a bound applies

Every public method of every resource class that reaches the daemon -- all of
them, with no exception for the ones whose arguments are the request body --
makes its request with the bounds in force. That is what the clone buys: the
method builds the request and the resource class it was called on says how
long to wait for it, so there is no list of methods that forward a bound and
no list of methods that cannot.

The requests a method makes on the caller's behalf without being asked are
bounded too, and for the same reason -- they run on the same resource class:

=over

=item * L<API::Docker::API::Containers/attach> asks whether the container is
running before attaching. That check carries the bounds the attach carries.

=item * L<API::Docker::API::Plugins/install> and
L<API::Docker::API::Plugins/upgrade> with C<< accept_privileges => 1 >> fetch
the plugin's privileges first. That fetch carries them too.

=item * L</negotiate_version> runs before the first request of a client with
no L</api_version>, and inherits the bounds of the request that triggered it:
C<< $docker->containers->using(read_timeout => 5)->list >> on a fresh client
bounds the C<GET /version> as well as the list. It is the one place the two
options are still written out per call, because it can be called directly and
is not reached through a resource class:

    $docker->negotiate_version(read_timeout => 5);

=back

The entity classes have no C<using> of their own; a bound for
C<< $container->logs >> goes on the resource class instead, see
L<API::Docker::Role::Using/"What has no clone of its own">.

=head1 CONTAINER ENGINES

This client speaks the Docker Engine HTTP API over a socket. It never shells
out to the C<docker> binary, so any engine serving that API works, whether or
not Docker itself is installed.

=head2 Installing Docker

Where the engine is Docker itself, prefer the official packages from
L<https://docs.docker.com/engine/install/> over a distribution package such as
Debian/Ubuntu's C<docker.io>, which is typically a good deal older. The reason
that matters here: L</negotiate_version> only negotiates within whatever API
version the daemon itself reports, so an older daemon still works, but
endpoints and query parameters that need a newer API version are then simply
not there. This is a recommendation about which Docker package to install, not
Docker instead of Podman -- Podman remains fully supported, see L</Podman>
below.

=head2 Podman

Podman ships a Docker-compatible API service. Enable its rootless socket and
point L</host> at it:

    systemctl --user enable --now podman.socket
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"

The socket announces API version 1.44, which L</negotiate_version> picks up
like any other daemon. Multi-stage builds are passed through unchanged,
C<target> included, down to skipping the stages the target does not depend on.

=head2 Engines and versions behind the measurements in this POD

Where this distribution's documentation says what an engine does rather than
what the Engine API reference says it should do, that statement was measured
against a real socket, not assumed. Three engines stand behind the
measurements found throughout this POD:

=over

=item * Podman 5.4.2, API 1.41

=item * Podman 5.8.4, API 1.44

=item * Docker 29.7.2, API 1.55

=back

Podman statements have been checked against both 5.4.2 and 5.8.4. Where an
individual statement names no version, it holds for both. A version named at
one particular measurement -- C<"Measured against Podman 5.4.2 (API 1.41):
...">, for instance -- names the engine that measurement was taken I<on>, not
the only engine it is claimed to hold for; read it as provenance, not as a
scope limit. Where a measurement genuinely is version-specific -- superseded
by a later one, or not re-checked on the other version -- the text says so.

=head2 Socket discovery

L</host> resolves in two steps and no more: C<$ENV{DOCKER_HOST}>, then
C<unix:///var/run/docker.sock>. It deliberately does B<not> read Docker
contexts. C<currentContext> in F<~/.docker/config.json> and the matching
F<~/.docker/contexts/meta/*/meta.json> are ignored, so if you switch daemons
with C<docker context use>, that choice is not picked up here. Set
C<DOCKER_HOST> explicitly instead.

Other clients sit at different points on that scale. The C<docker> CLI and
docker-java resolve contexts, with C<DOCKER_HOST> outranking them when set.
docker-py's C<from_env()> reads C<DOCKER_HOST> and otherwise falls back to the
default socket, leaving contexts to a separate API. Testcontainers layers its
own F<~/.testcontainers.properties> and a rootless probe list
(C<$XDG_RUNTIME_DIR/docker.sock>, F<~/.docker/run/docker.sock>,
F<~/.docker/desktop/docker.sock>, C</run/user/$UID/docker.sock>) on top.

What none of them do is guess Podman's socket path: that probe list is for
rootless Docker, not for Podman. Every one of those projects documents
C<DOCKER_HOST> as the way to reach Podman, which is the same answer given
above.

=head1 ENVIRONMENT VARIABLES

=over

=item C<DOCKER_HOST>

Docker daemon connection URL. Used as default for L</host> if not explicitly set.

Examples: C<unix:///var/run/docker.sock>, C<tcp://localhost:2375>

Also the supported way to reach a non-Docker engine such as Podman:
C<unix://$XDG_RUNTIME_DIR/podman/podman.sock>. See L</CONTAINER ENGINES>.

=item C<DOCKER_CERT_PATH>

Path to the TLS certificate directory (F<ca.pem>, F<cert.pem>, F<key.pem>).
Used as the default for L</cert_path>, which is read only when L</tls> is set
-- so having it exported, as machines running the C<docker> CLI usually do,
changes nothing for a client that speaks plaintext or over a Unix socket.

=back

=head1 SEE ALSO

=over

=item * L<API::Docker::Role::HTTP> - HTTP transport implementation

=item * L<API::Docker::Role::RegistryAuth> - X-Registry-Auth / AuthConfig
encoding

=item * L<API::Docker::Role::Filters> - the C<filters> query parameter

=item * L<API::Docker::Role::Using> - C<using>, the resource class clone that
bounds a run of calls

=item * L<API::Docker::Type> - the DSL and attribute registry behind the
generated C<API::Docker::Type::*> classes

=item * L<API::Docker::Role::Type> - the generated classes' own behaviour

=item * L<API::Docker::Role::Entity> - the client reference an entity
delegates through

=item * L<API::Docker::Role::Entity::Container> - the container convenience
methods, composed onto the generated container classes

=item * L<API::Docker::API::System> - System and daemon operations

=item * L<API::Docker::API::Containers> - Container management

=item * L<API::Docker::API::Images> - Image management

=item * L<API::Docker::API::Networks> - Network management

=item * L<API::Docker::API::Volumes> - Volume management

=item * L<API::Docker::API::Exec> - Execute commands in containers

=item * L<API::Docker::API::Distribution> - Registry manifest lookups

=item * L<API::Docker::API::Secrets> - Swarm secrets

=item * L<API::Docker::API::Configs> - Swarm configs

=item * L<API::Docker::API::Plugins> - Managed plugins

=item * L<API::Docker::Error::HTTP> - Raised for a status of 400 or above,
carries the status code

=item * L<API::Docker::Error::Stream> - Raised for a failure reported inside a
200 event stream

=item * L<API::Docker::Error::Timeout> - Raised when a request given a
C<read_timeout> or C<connect_timeout> runs out of it

=item * L<API::Docker::Error::Truncated> - Raised when the daemon closed
before the response it announced was complete

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
