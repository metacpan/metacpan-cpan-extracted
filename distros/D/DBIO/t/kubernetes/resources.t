use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test::Kubernetes;

# Offline test for the resource-limit policy of DBIO::Test::Kubernetes.
#
# WHY this is pinned: these pods run on small shared machines next to other
# databases and services. An unlimited container that nobody remembers to
# delete can starve or OOM the whole host -- that has happened. The invariant
# under test is therefore not "the numbers are 1Gi" but "nothing this module
# creates can end up without cpu AND memory limits", including via a caller
# that tries to opt out.
#
# No cluster, no kubeconfig, no Kubernetes::REST: a fake API object records
# the objects the module builds and we assert on those.

{
    package FakeAPI;
    sub new { bless { created => [] }, shift }

    # Kubernetes::REST's factory -- we only care about the structure handed
    # to it, so hand it straight back with the kind attached.
    sub new_object {
        my ($self, $kind, %args) = @_;
        return { kind => $kind, %args };
    }

    sub create {
        my ($self, $obj) = @_;
        push @{ $self->{created} }, $obj;
        return $obj;
    }

    sub created { @{ $_[0]{created} } }
    sub of_kind {
        my ($self, $kind) = @_;
        return grep { $_->{kind} eq $kind } $self->created;
    }
}

# Build an instance without going through new(), which needs a kubeconfig and
# a live Kubernetes::REST stack.
sub k8s_with {
    my ($api, @databases) = @_;
    return bless {
        kubeconfig        => '/nonexistent/kubeconfig',
        namespace         => 'dbio-test-offline',
        databases         => (@databases ? [@databases] : ['pg']),
        api               => $api,
        port_forward_pids => [],
        local_ports       => {},
        _deployed         => 0,
        _ready            => 0,
    }, 'DBIO::Test::Kubernetes';
}

# The module narrates its progress on STDOUT; keep that out of the TAP stream.
sub quietly {
    my ($code) = @_;
    my $out = '';
    open my $fh, '>', \$out or die "cannot open in-memory handle: $!";
    my @ret = do {
        local *STDOUT = $fh;
        $code->();
    };
    close $fh;
    return wantarray ? @ret : $ret[0];
}

sub container_of {
    my ($obj) = @_;
    return $obj->{kind} eq 'Job'
        ? $obj->{spec}{template}{spec}{containers}[0]
        : $obj->{spec}{containers}[0];
}

my %MINIMAL_SPEC = (
    name          => 'pg',
    image         => 'postgres:16',
    port          => 5432,
    svc_name      => 'pg-svc',
    env           => [],
    readiness_cmd => [qw(pg_isready -U postgres)],
);

# --- default envelope -------------------------------------------------------

{
    my $api = FakeAPI->new;
    quietly(sub { k8s_with($api)->_deploy_db({ %MINIMAL_SPEC }) });

    my ($pod) = $api->of_kind('Pod');
    my $res = container_of($pod)->{resources};

    ok($res, 'pod container carries a resources block by default');
    is_deeply(
        $res,
        {
            requests => { cpu => '250m', memory => '256Mi' },
            limits   => { cpu => '1',    memory => '1Gi'   },
        },
        'default envelope matches the family manifests (one core, 1Gi)',
    );
}

# --- every database spec, not just the one we happened to pick --------------

{
    my $api = FakeAPI->new;
    quietly(sub {
        k8s_with($api, qw(pg pg-ext mysql duckdb))->deploy_databases;
    });

    my @pods = $api->of_kind('Pod');
    is(scalar @pods, 4, 'all four shipped database specs deployed');

    for my $pod (@pods) {
        my $name   = $pod->{metadata}{name};
        my $limits = container_of($pod)->{resources}{limits};
        ok(defined $limits->{cpu} && length $limits->{cpu},
            "$name: cpu limit set");
        ok(defined $limits->{memory} && length $limits->{memory},
            "$name: memory limit set");
    }
}

# --- a caller may raise the ceiling ----------------------------------------

{
    my $api = FakeAPI->new;
    my $custom = {
        requests => { cpu => '500m', memory => '512Mi' },
        limits   => { cpu => '2',    memory => '4Gi'   },
    };
    quietly(sub {
        k8s_with($api)->_deploy_db({ %MINIMAL_SPEC, resources => $custom });
    });

    my ($pod) = $api->of_kind('Pod');
    is_deeply(container_of($pod)->{resources}, $custom,
        'a spec-supplied resources block wins over the default');
}

# --- the opt-out is closed --------------------------------------------------
#
# Each of these is a way of saying "no limits, please". None may be honoured,
# and none may leave a container behind.

my @no_limits = (
    [ 'resources => undef'          => undef ],
    [ 'empty resources hash'        => {} ],
    [ 'requests but no limits'      => { requests => { cpu => '1', memory => '1Gi' } } ],
    [ 'limits without cpu'          => { limits => { memory => '1Gi' } } ],
    [ 'limits without memory'       => { limits => { cpu => '1' } } ],
    [ 'empty limits hash'           => { limits => {} } ],
    [ 'limits as a non-hash'        => { limits => 'none' } ],
);

for my $case (@no_limits) {
    my ($desc, $resources) = @$case;
    my $api = FakeAPI->new;

    throws_ok {
        quietly(sub {
            k8s_with($api)->_deploy_db({ %MINIMAL_SPEC, resources => $resources });
        });
    } qr/without cpu and memory limits/,
        "pod: $desc is refused";

    is(scalar($api->created), 0, "pod: $desc created nothing");
}

# --- the in-cluster test Job is held to the same rule -----------------------

{
    my $api = FakeAPI->new;
    quietly(sub { k8s_with($api)->deploy_test_job });

    my ($job) = $api->of_kind('Job');
    my $res = container_of($job)->{resources};

    ok($res, 'test Job container carries a resources block');
    ok(defined $res->{limits}{cpu} && length $res->{limits}{cpu},
        'test Job: cpu limit set');
    ok(defined $res->{limits}{memory} && length $res->{limits}{memory},
        'test Job: memory limit set');
    is($res->{limits}{cpu}, '1',
        'test Job stays within one core on a shared box');
    ok($res->{requests}, 'test Job also declares requests');
}

{
    my $api = FakeAPI->new;
    my $custom = {
        requests => { cpu => '250m', memory => '256Mi' },
        limits   => { cpu => '1',    memory => '2Gi'   },
    };
    quietly(sub { k8s_with($api)->deploy_test_job(resources => $custom) });

    my ($job) = $api->of_kind('Job');
    is_deeply(container_of($job)->{resources}, $custom,
        'a caller-supplied resources block wins for the test Job too');
}

{
    my $api = FakeAPI->new;
    throws_ok {
        quietly(sub { k8s_with($api)->deploy_test_job(resources => {}) });
    } qr/without cpu and memory limits/,
        'test Job: opting out of limits is refused';
    is(scalar($api->created), 0, 'test Job: opting out created nothing');
}

done_testing;
