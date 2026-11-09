use strict;
use warnings;
use Test::More;

use DBIO::Test::Kubernetes;

# Offline test for the MySQL readiness probe of DBIO::Test::Kubernetes (k208).
#
# WHY this is pinned: the mysql image's entrypoint boots a TEMPORARY server
# with --skip-networking (socket only, "port: 0") to run its init scripts,
# stops it, and only then starts the real server on 3306. A probe that talks
# to mysqld over the unix socket -- `mysqladmin ping -h localhost` was the
# old one -- succeeds against that temporary server, so the pod went Ready
# ~5s before anything listened on 3306 and live suites connecting in that
# window died with "connection refused" (observed live on the test cluster).
#
# The invariant is therefore "Ready is only reachable over TCP": the probe
# must force the TCP protocol to the loopback address. The live proof that
# the probe really fails against the socket-only server lives in the k208
# ticket notes; this test keeps the probe from drifting back to the socket.

{
    package FakeAPI;
    sub new { bless { created => [] }, shift }
    sub new_object {
        my ($self, $kind, %args) = @_;
        return { kind => $kind, %args };
    }
    sub create { push @{ $_[0]{created} }, $_[1]; $_[1] }
    sub of_kind {
        my ($self, $kind) = @_;
        return grep { $_->{kind} eq $kind } @{ $self->{created} };
    }
}

my $api = FakeAPI->new;
my $k8s = bless {
    kubeconfig        => '/nonexistent/kubeconfig',
    namespace         => 'dbio-test-offline',
    databases         => ['mysql'],
    api               => $api,
    port_forward_pids => [],
    local_ports       => {},
    _deployed         => 0,
    _ready            => 0,
}, 'DBIO::Test::Kubernetes';

{
    my $out = '';
    open my $fh, '>', \$out or die "cannot open in-memory handle: $!";
    local *STDOUT = $fh;
    $k8s->deploy_databases;
}

my ($pod) = $api->of_kind('Pod');
ok $pod, 'a mysql pod was built';

my $probe = $pod->{spec}{containers}[0]{readinessProbe};
my $cmd   = join ' ', @{ $probe->{exec}{command} // [] };

like $cmd, qr/--protocol=TCP\b/,
    'probe forces TCP -- the temporary init server has no TCP listener';
like $cmd, qr/-h\s+127\.0\.0\.1\b/,
    'probe targets the loopback address, not "localhost" (socket alias)';
like $cmd, qr/-P\s+3306\b/, 'probe hits the port clients connect to';
unlike $cmd, qr/\bmysqladmin\s+ping\b/,
    'probe is not mysqladmin ping (passes on the socket-only init server)';
like $cmd, qr/SELECT 1.*dbio_test/,
    'probe runs a real query against the database the DSN names';

done_testing;
