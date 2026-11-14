package DBIO::Test::Kubernetes;
# ABSTRACT: Provision temporary database pods in Kubernetes for DBIO testing
use strict;
use warnings;

our $VERSION = '0.900005';

use Carp qw(croak);
use DBIO::Exception ();
use DBIO::Optional::Dependencies ();
use DBIO::Util ();
use POSIX qw(WNOHANG);
use namespace::clean;



sub new {
    my ($class, %args) = @_;

    my $kubeconfig = $args{kubeconfig}
        // $ENV{DBIO_TEST_KUBECONFIG}
        // $ENV{KUBECONFIG}
        // DBIO::Util::file_path($ENV{HOME}, '.kube', 'config');

    croak "Kubeconfig not found: $kubeconfig" unless -f $kubeconfig;

    # Two ways to name the namespace, and they are not interchangeable: one is
    # created and deleted by this run, the other is somebody else's and is
    # neither. Which one applies is said by the caller, never worked out from
    # what the cluster permits (see NAMESPACES).
    DBIO::Exception->throw("Pass either namespace or existing_namespace, not both")
        if defined $args{namespace} && exists $args{existing_namespace};
    DBIO::Exception->throw("existing_namespace needs the name of the namespace to work in")
        if exists $args{existing_namespace}
            && !(defined $args{existing_namespace} && length $args{existing_namespace});

    my $existing  = exists $args{existing_namespace} ? 1 : 0;
    my $namespace = $existing
        ? $args{existing_namespace}
        : $args{namespace} // _generate_namespace();
    my $databases = $args{databases} // [qw(pg mysql)];

    # Validate database names
    my %valid = map { $_ => 1 } qw(pg mysql pg-ext duckdb);
    for my $db (@$databases) {
        croak "Unknown database: $db (valid: pg, mysql, pg-ext, duckdb)" unless $valid{$db};
    }

    require Kubernetes::REST::Kubeconfig;
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => $kubeconfig,
    );
    my $api = $kc->api;

    return bless {
        kubeconfig      => $kubeconfig,
        namespace       => $namespace,
        existing_namespace => $existing,
        run_id          => _generate_suffix(),
        databases       => $databases,
        api             => $api,
        port_forward_pids => [],
        local_ports     => {},
        _created        => [],
        _deployed       => 0,
        _ready          => 0,
    }, $class;
}


sub namespace  { $_[0]->{namespace} }


sub databases  { $_[0]->{databases} }


sub api        { $_[0]->{api} }


sub kubeconfig { $_[0]->{kubeconfig} }


sub uses_existing_namespace { $_[0]->{existing_namespace} ? 1 : 0 }


sub created_objects { @{ $_[0]->{_created} // [] } }

sub _generate_suffix {
    my @chars = ('a'..'z', '0'..'9');
    return join '', map { $chars[rand @chars] } 1..8;
}

sub _generate_namespace { 'dbio-test-' . _generate_suffix() }

# ============================================================================
# OBJECT NAMES AND LABELS
# ============================================================================

# A namespace of our own is the isolation, so the names in it are the plain
# ones. In somebody else's namespace a plain name is a collision waiting to
# happen (a Pod `mysql` and a Service `mysql-svc` are exactly what a hand-run
# test database is called), so every name carries this run's id.
sub _object_name {
    my ($self, $base) = @_;

    return $base unless $self->{existing_namespace};
    return "dbio-test-$self->{run_id}-$base";
}

sub _job_name {
    my ($self) = @_;

    return 'dbio-test-runner' unless $self->{existing_namespace};
    return $self->_object_name('runner');
}

# Labels are the sharper edge. A Service selects by label, not by name: a pod
# of ours labelled app=mysql in a namespace that already has a Service
# selecting app=mysql becomes one of that Service's endpoints, and a share of
# its traffic lands on our throwaway pod. So in an existing namespace a pod
# carries only label keys that belong to this module, one of them the run id
# -- nothing a selector written by anybody else can match.
sub _pod_labels {
    my ($self, $db) = @_;

    return { app => $db, role => 'dbio-test-db' }
        unless $self->{existing_namespace};
    return { 'dbio-test-run' => $self->{run_id}, 'dbio-test-db' => $db };
}

# Service and Job are not selected by anything of ours, but they are left
# behind just as well by a run that dies. In an existing namespace they carry
# the run id as a label, so that one label finds every object of a run
# (maint/live-preflight). Metadata only: no selector reads a Service's or a
# Job's own labels. Empty list in a namespace of our own.
sub _run_labels {
    my ($self) = @_;

    return () unless $self->{existing_namespace};
    return ( labels => { 'dbio-test-run' => $self->{run_id} } );
}

# What the Service of a database selects: its own pod and no other -- in an
# existing namespace that takes the run id, or two concurrent runs would
# serve each other's connections.
sub _pod_selector {
    my ($self, $db) = @_;

    return { app => $db } unless $self->{existing_namespace};
    return $self->_pod_labels($db);
}

# Every object goes through here, and is written down the moment the API has
# accepted it. cleanup works from that list alone, so a deploy that dies
# halfway leaves nothing behind, and nothing is ever deleted that this run did
# not create: a create that fails (the name is taken, the quota is full) is
# not recorded.
sub _create {
    my ($self, $kind, %args) = @_;

    my $api = $self->api;
    $api->create($api->new_object($kind => %args));
    push @{ $self->{_created} }, { kind => $kind, name => $args{metadata}{name} };

    return;
}

# ============================================================================
# RESOURCE LIMITS
# ============================================================================

# The ONE place the default container resource envelope lives. Both the
# database pods and the in-cluster test Job resolve through here, so the call
# sites cannot drift apart. The values match the checked-in manifests of the
# driver distributions (maint/k8s/*.yaml): at most one core, because these
# suites run on small shared machines next to other databases and services.
#
# Returns a fresh hashref on every call -- the result is handed to the k8s
# object builder, which must not end up aliasing a shared structure.
sub _default_resources {
    return {
        requests => { cpu => '250m', memory => '256Mi' },
        limits   => { cpu => '1',    memory => '1Gi'   },
    };
}

# Resolve the resources block for one container.
#
# A spec may carry its own `resources` to raise the ceiling for a heavier
# engine. What it may NOT do is ask for no limits: an unbounded container is
# precisely the failure this mechanism exists to prevent, and a forgotten one
# can take a shared host down with it.
#
# That case throws rather than warning-and-defaulting. A warning scrolls past
# in the provisioning output and the container gets created anyway, which is
# the exact shape we are trying to make unreachable; the caller learns nothing
# until the box is already under pressure. Throwing means an unlimited
# container cannot be produced from here at all -- a caller that wants a
# different ceiling has to name it.
#
# Half-specified limits (cpu but no memory, or the reverse) are rejected for
# the same reason: memory is what OOMs the host, cpu is what starves it, and
# leaving either open is not meaningfully safer than leaving both open.
sub _resources_for {
    my ($spec, $what) = @_;

    return _default_resources() unless exists $spec->{resources};

    my $res    = $spec->{resources};
    my $limits = ref $res eq 'HASH' ? $res->{limits} : undef;

    croak "Refusing to create $what without cpu and memory limits: every "
        . "container created here must carry resources.limits (see the "
        . "RESOURCE LIMITS section of DBIO::Test::Kubernetes)"
        unless ref $limits eq 'HASH'
            && defined $limits->{cpu}    && length $limits->{cpu}
            && defined $limits->{memory} && length $limits->{memory};

    return $res;
}

# ============================================================================
# DATABASE SPECS
# ============================================================================

my %DB_SPECS = (
    pg => {
        name       => 'pg',
        image      => 'postgres:16',
        port       => 5432,
        svc_name   => 'pg-svc',
        env        => [
            { name => 'POSTGRES_PASSWORD', value => 'dbiotest' },
            { name => 'POSTGRES_DB',       value => 'dbio_test' },
        ],
        readiness_cmd => [qw(pg_isready -U postgres)],
        dsn_template  => 'dbi:Pg:database=dbio_test;host=%s;port=%s',
        user          => 'postgres',
        pass          => 'dbiotest',
        env_prefix    => 'DBIO_TEST_PG',
    },
    'pg-ext' => {
        name       => 'pg-ext',
        image      => 'src.ci/srv/postgres:18',
        port       => 5432,
        svc_name   => 'pg-ext-svc',
        env        => [
            { name => 'POSTGRES_PASSWORD', value => 'dbiotest' },
            { name => 'POSTGRES_DB',       value => 'postgres' },
            { name => 'POSTGRES_HOST_AUTH_METHOD', value => 'scram-sha-256' },
        ],
        readiness_cmd => [qw(pg_isready -U postgres)],
        dsn_template  => 'dbi:Pg:database=postgres;host=%s;port=%s',
        user          => 'postgres',
        pass          => 'dbiotest',
        env_prefix    => 'DBIO_TEST_PG_EXT',
    },
    mysql => {
        name       => 'mysql',
        # PINNED to 8.0.30, the last 8.0.x that runs on a plain x86-64 (v1)
        # CPU: mysql:8.0.31+ dies with "Fatal glibc error: CPU does not
        # support x86-64-v2" on a node without that baseline (k206). It was
        # first set for the old test cluster; the workers of the HQ cluster
        # (kaiser) do have v2 -- but not v3/AVX2 -- so the pin is no longer
        # forced, only still harmless. Not lifted here because
        # xbin/k8s/mysql-pod.yaml, which dbio-db runs the standing database
        # from, carries the same image and has to move with it.
        image      => 'mysql:8.0.30',
        port       => 3306,
        svc_name   => 'mysql-svc',
        env        => [
            { name => 'MYSQL_ROOT_PASSWORD', value => 'dbiotest' },
            { name => 'MYSQL_DATABASE',      value => 'dbio_test' },
        ],
        # Ready means "a TCP client can run SQL against dbio_test", not
        # "mysqld answers on its socket". The image's entrypoint first boots a
        # TEMPORARY server with --skip-networking (socket only, "port: 0") to
        # run the init scripts, stops it, then starts the real server on 3306.
        # `mysqladmin ping -h localhost` goes over the socket, so it passed on
        # the temporary server and marked the pod Ready ~5s before anything
        # listened on 3306 -- every client connecting in that window got
        # "connection refused" (k208, observed live). Forcing TCP to 127.0.0.1
        # cannot succeed until the real server is up, and running a query
        # against the DSN's database proves auth + schema, not just a socket.
        readiness_cmd => [
            'sh', '-c',
            'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql --protocol=TCP'
            . ' -h 127.0.0.1 -P 3306 -u root -e "SELECT 1" dbio_test',
        ],
        # Probed, never loaded: this table is built when the module is loaded,
        # so a require here initialises an XS database driver plus DBI in every
        # process that merely loads this file -- for a template string (k179,
        # same coupling as k173).
        dsn_template  => (
            DBIO::Optional::Dependencies::_module_findable('DBD/MariaDB.pm')
            ? 'dbi:MariaDB:database=dbio_test;host=%s;port=%s'
            : 'dbi:mysql:database=dbio_test;host=%s;port=%s'
        ),
        user          => 'root',
        pass          => 'dbiotest',
        env_prefix    => 'DBIO_TEST_MYSQL',
    },
    duckdb => {
        name       => 'duckdb',
        image      => 'duckdb/duckdb:latest',
        port       => 5432,
        svc_name   => 'duckdb-svc',
        env        => [
            { name => 'DUCKDB_PASSWORD', value => 'dbiotest' },
        ],
        readiness_probe => {
            tcpSocket => { port => 5432 },
            initialDelaySeconds => 5,
            periodSeconds       => 3,
            timeoutSeconds      => 2,
            failureThreshold    => 10,
        },
        dsn_template  => 'dbi:DuckDB:database=dbio_test;host=%s;port=%s',
        user          => 'duckdb',
        pass          => 'dbiotest',
        env_prefix    => 'DBIO_TEST_DUCKDB',
    },
);

# ============================================================================
# DEPLOY
# ============================================================================


sub deploy_databases {
    my ($self) = @_;

    my $ns = $self->namespace;

    if ($self->{existing_namespace}) {
        print "Using existing namespace $ns (run $self->{run_id})...\n";
    } else {
        print "Creating namespace $ns...\n";
        $self->_create(Namespace =>
            metadata => { name => $ns },
        );
    }

    # Deploy each database
    for my $db (@{$self->databases}) {
        my $spec = $DB_SPECS{$db} or croak "No spec for database: $db";
        $self->_deploy_db($spec);
    }

    $self->{_deployed} = 1;
}

sub _deploy_db {
    my ($self, $spec) = @_;

    my $ns = $self->namespace;

    print "Deploying $spec->{name} pod...\n";

    # Create Pod
    $self->_create(Pod =>
        metadata => {
            name      => $self->_object_name($spec->{name}),
            namespace => $ns,
            labels    => $self->_pod_labels($spec->{name}),
        },
        spec => {
            containers => [{
                name      => $spec->{name},
                image     => $spec->{image},
                ports     => [{ containerPort => $spec->{port} }],
                env       => $spec->{env},
                resources => _resources_for($spec, "database pod $spec->{name}"),
                ( $spec->{readiness_probe}
                  ? ( readinessProbe => $spec->{readiness_probe} )
                  : ( readinessProbe => {
                        exec => { command => $spec->{readiness_cmd} },
                        initialDelaySeconds => 5,
                        periodSeconds       => 3,
                        timeoutSeconds      => 2,
                        failureThreshold    => 30,
                    } )
                ),
            }],
        },
    );

    # Create Service
    $self->_create(Service =>
        metadata => {
            name      => $self->_object_name($spec->{svc_name}),
            namespace => $ns,
            $self->_run_labels,
        },
        spec => {
            selector => $self->_pod_selector($spec->{name}),
            ports    => [{
                port       => $spec->{port},
                targetPort => $spec->{port},
                protocol   => 'TCP',
            }],
        },
    );
}

# ============================================================================
# READINESS
# ============================================================================

# One poll step: the object, or undef when the API says it is not there (yet).
# Any other failure -- a 403, an expired token, a refused connection -- is the
# caller's problem and propagates; swallowing it made it look like the object
# merely was not ready, and the wait ended as a plain timeout.
sub _get_or_none {
    my ($self, $kind, $name, $ns) = @_;

    my $obj = eval { $self->api->get($kind, $name, namespace => $ns) };
    return $obj unless my $err = $@;

    return undef if "$err" =~ /\b404\b|\bnot\s*found\b/i;
    DBIO::Exception->throw("Reading $kind $name in $ns failed: $err");
}


sub wait_for_ready {
    my ($self, %opts) = @_;

    my $timeout  = $opts{timeout} // 120;
    my $interval = $opts{interval} // 3;

    croak "Must call deploy_databases first" unless $self->{_deployed};

    my $api = $self->api;
    my $ns  = $self->namespace;
    my $deadline = time + $timeout;

    for my $db (@{$self->databases}) {
        print "Waiting for $db to be ready...\n";

        while (time < $deadline) {
            my $pod = $self->_get_or_none('Pod',
                $self->_object_name($DB_SPECS{$db}{name}), $ns);
            if ($pod && $pod->status) {
                my $conditions = $pod->status->conditions;
                if ($conditions) {
                    for my $cond (@$conditions) {
                        if ($cond->type eq 'Ready' && $cond->status eq 'True') {
                            print "$db is ready.\n";
                            goto NEXT_DB;
                        }
                    }
                }
            }
            sleep $interval;
        }

        croak "Timed out waiting for $db to become ready (${timeout}s)";
        NEXT_DB:
    }

    $self->{_ready} = 1;
}

# ============================================================================
# CONNECTION INFO
# ============================================================================


sub connection_info {
    my ($self, %opts) = @_;

    my $mode = $opts{mode} // 'local';
    my $ns   = $self->namespace;
    my %info;

    for my $db (@{$self->databases}) {
        my $spec = $DB_SPECS{$db};

        my ($host, $port);
        if ($mode eq 'cluster') {
            $host = $self->_object_name($spec->{svc_name}) . ".$ns.svc.cluster.local";
            $port = $spec->{port};
        } else {
            # local mode -- use port-forward ports
            $host = '127.0.0.1';
            $port = $self->{local_ports}{$db}
                or croak "No local port for $db -- call setup_port_forwards first";
        }

        $info{$db} = {
            dsn  => sprintf($spec->{dsn_template}, $host, $port),
            user => $spec->{user},
            pass => $spec->{pass},
            host => $host,
            port => $port,
        };
    }

    return \%info;
}


sub env_vars {
    my ($self, %opts) = @_;

    my $info = $self->connection_info(%opts);
    my %env;

    for my $db (keys %$info) {
        my $spec   = $DB_SPECS{$db};
        my $prefix = $spec->{env_prefix};

        $env{"${prefix}_DSN"}  = $info->{$db}{dsn};
        $env{"${prefix}_USER"} = $info->{$db}{user};
        $env{"${prefix}_PASS"} = $info->{$db}{pass};

}

    return %env;
}

# ============================================================================
# PORT FORWARDING (local mode)
# ============================================================================


sub setup_port_forwards {
    my ($self) = @_;

    croak "Must call deploy_databases and wait_for_ready first"
        unless $self->{_ready};

    my $ns = $self->namespace;

    for my $db (@{$self->databases}) {
        my $spec = $DB_SPECS{$db};
        my $svc_name   = $self->_object_name($spec->{svc_name});
        my $local_port = _find_free_port();

        $self->{local_ports}{$db} = $local_port;

        print "Port-forwarding $svc_name to 127.0.0.1:$local_port...\n";

        my $pid = fork();
        if (!defined $pid) {
            croak "fork failed: $!";
        }
        if ($pid == 0) {
            # child
            exec('kubectl',
                '--kubeconfig=' . $self->kubeconfig,
                'port-forward',
                '-n', $ns,
                "svc/$svc_name",
                "$local_port:$spec->{port}",
            );
            die "exec kubectl failed: $!";
        }

        push @{$self->{port_forward_pids}}, $pid;
    }

    # Give port-forwards a moment to establish
    sleep 2;

    # Verify they're still running
    for my $pid (@{$self->{port_forward_pids}}) {
        my $res = waitpid($pid, WNOHANG);
        if ($res != 0) {
            croak "Port-forward process $pid died unexpectedly";
        }
    }
}

sub _find_free_port {
    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or croak "Cannot find free port: $!";
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

# ============================================================================
# IN-CLUSTER JOB MODE
# ============================================================================


sub deploy_test_job {
    my ($self, %opts) = @_;

    my $ns    = $self->namespace;
    my $name  = $self->_job_name;
    my $image = $opts{image} // 'dbio-test:latest';
    my @args  = @{$opts{prove_args} // ['-l', 't/']};

    # Build env vars for in-cluster mode
    my %env = $self->env_vars(mode => 'cluster');
    my @env_list = map {
        { name => $_, value => $env{$_} }
    } sort keys %env;

    print "Deploying test Job in namespace $ns...\n";

    $self->_create(Job =>
        metadata => {
            name      => $name,
            namespace => $ns,
            $self->_run_labels,
        },
        spec => {
            backoffLimit => 0,
            template => {
                spec => {
                    restartPolicy => 'Never',
                    containers => [{
                        name    => 'test-runner',
                        image   => $image,
                        command => ['prove'],
                        args    => \@args,
                        env     => \@env_list,
                        # The runner is not a database, so the envelope was
                        # reconsidered rather than assumed -- but it lands on
                        # the same numbers. CPU: the one-core cap is not about
                        # this workload's appetite (prove would happily eat
                        # every core), it is the shared-box ceiling, and it
                        # applies to the greediest tenant first. Memory: steady
                        # state is a chain of small short-lived perl processes,
                        # but a --cover run keeps Devel::Cover's coverage db in
                        # memory for the whole suite, and that is the real
                        # high-water mark; 1Gi covers it. Keeping the runner on
                        # the same ceiling as the DB pods also makes the
                        # namespace's worst case easy to reason about.
                        resources => _resources_for(\%opts, 'test Job container'),
                    }],
                },
            },
        },
    );

    return $name;
}


sub wait_for_job {
    my ($self, %opts) = @_;

    my $job_name = $opts{name} // $self->_job_name;
    my $timeout  = $opts{timeout} // 3600;
    my $interval = $opts{interval} // 5;

    my $api = $self->api;
    my $ns  = $self->namespace;
    my $deadline = time + $timeout;

    print "Waiting for Job $job_name to complete...\n";

    while (time < $deadline) {
        my $job = $self->_get_or_none('Job', $job_name, $ns);

        if ($job && $job->status) {
            my $succeeded = $job->status->succeeded;
            my $failed    = $job->status->failed;

            if ($succeeded && $succeeded > 0) {
                print "Job succeeded.\n";
                return 0;  # exit code 0
            }
            if ($failed && $failed > 0) {
                print "Job failed.\n";
                return 1;  # exit code 1
            }
        }
        sleep $interval;
    }

    croak "Timed out waiting for Job $job_name (${timeout}s)";
}


sub fetch_job_logs {
    my ($self, %opts) = @_;

    my $job_name = $opts{name} // $self->_job_name;
    my $api = $self->api;
    my $ns  = $self->namespace;

    # Find pods belonging to the job
    my $pods = $api->list('Pod',
        namespace     => $ns,
        labelSelector => "job-name=$job_name",
    );

    my @logs;
    for my $pod (@{ $pods->items }) {
        my $pod_name = $pod->metadata->name;

        # Use kubectl for logs since Kubernetes::REST doesn't expose pod logs directly
        my $log = `kubectl --kubeconfig=${\$self->kubeconfig} logs -n $ns $pod_name 2>&1`;
        push @logs, { pod => $pod_name, log => $log };
    }

    return \@logs;
}

# ============================================================================
# CLEANUP
# ============================================================================


sub cleanup {
    my ($self) = @_;

    # Kill port-forward processes
    for my $pid (@{$self->{port_forward_pids}}) {
        kill 'TERM', $pid;
        waitpid($pid, 0);
    }
    $self->{port_forward_pids} = [];

    # Delete what this run created -- by kind and exact name, from the list
    # _create keeps, never by a label selector: a selector deletes whatever
    # matches it, including what matched before this run began.
    my $ns      = $self->namespace;
    my @created = @{ $self->{_created} // [] };

    # A namespace this run created takes everything in it along (cascading
    # delete), so that one delete is the whole job. A namespace that was
    # already there is not in the list, and is never deleted.
    my ($own_ns) = grep { $_->{kind} eq 'Namespace' } @created;
    my @targets  = $own_ns ? ($own_ns) : reverse @created;

    my %gone;
    for my $obj (@targets) {
        my ($kind, $name) = @{$obj}{qw(kind name)};
        my $what = $kind eq 'Namespace'
            ? "namespace $name"
            : "$kind $name in namespace $ns";
        print "Deleting $what...\n";
        eval {
            $self->api->delete($kind, $name,
                $kind eq 'Namespace' ? () : (namespace => $ns),
                # Asked through the REST API, a Job is deleted without its
                # pods unless told otherwise. In a namespace of our own the
                # namespace delete collects them; here nothing would.
                $kind eq 'Job' ? (propagationPolicy => 'Background') : (),
            );
            $gone{$obj} = 1;
        };
        if ($@) {
            warn "Warning: failed to delete $what: $@\n";
        }
    }

    # Keep what could not be deleted, so created_objects still names it and a
    # second cleanup tries again; forget the rest, so it is deleted only once.
    $self->{_created} = $own_ns
        ? ( $gone{$own_ns} ? [] : \@created )
        : [ grep { !$gone{$_} } @created ];
}

sub DESTROY {
    my ($self) = @_;

    # Kill any leftover port-forward processes
    for my $pid (@{$self->{port_forward_pids} // []}) {
        kill 'TERM', $pid;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Kubernetes - Provision temporary database pods in Kubernetes for DBIO testing

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

    my $k8s = DBIO::Test::Kubernetes->new(
        kubeconfig => $path,
        databases  => [qw(pg mysql)],
    );

    $k8s->deploy_databases;
    $k8s->wait_for_ready;

    # Local mode: port-forward and get env vars
    $k8s->setup_port_forwards;
    my %env = $k8s->env_vars;
    local @ENV{keys %env} = values %env;
    system('prove', '-Ilib', 't/');

    $k8s->cleanup;

    # In a namespace that is already there (and stays there)
    my $k8s = DBIO::Test::Kubernetes->new(
        existing_namespace => 'dev-dbio',
        databases          => [qw(pg mysql)],
    );

See F<t/kubernetes/smoke.t> for a runnable example.

=head1 DESCRIPTION

L<DBIO::Test::Kubernetes> provisions temporary test databases inside
Kubernetes and exposes the corresponding C<DBIO_TEST_*>
environment variables for local or in-cluster test runs.

It is intended for integration-style test runs that need short-lived database
instances without hand-managed local services or bespoke local containers.

C<databases> takes any of the following names and defaults to C<pg> and
C<mysql>; any other name croaks. C<env_vars> returns
C<< <prefix>_DSN >>, C<< <prefix>_USER >> and C<< <prefix>_PASS >> for each
database, with the prefix given here:

=over 4

=item * C<pg> -- image C<postgres:16>, prefix C<DBIO_TEST_PG>

=item * C<pg-ext> -- image C<src.ci/srv/postgres:18>, prefix C<DBIO_TEST_PG_EXT>

=item * C<mysql> -- image C<mysql:8.0.30>, prefix C<DBIO_TEST_MYSQL>

=item * C<duckdb> -- image C<duckdb/duckdb:latest>, prefix C<DBIO_TEST_DUCKDB>

=back

=head1 METHODS

=head2 new

    my $k8s = DBIO::Test::Kubernetes->new(
        kubeconfig         => $path,                   # optional
        databases          => [qw(pg mysql)],          # optional
        namespace          => 'my-run',                # or:
        existing_namespace => 'dev-dbio',              # one of the two
    );

Builds the run; nothing is created in the cluster yet. The kubeconfig is
C<kubeconfig>, else C<$ENV{DBIO_TEST_KUBECONFIG}>, else C<$ENV{KUBECONFIG}>,
else F<~/.kube/config>; a file that is not there croaks. C<databases> names
what to deploy (see L</DESCRIPTION>) and an unknown name croaks.
C<namespace> and C<existing_namespace> are the two kinds described under
L</NAMESPACES>; giving both, or an empty C<existing_namespace>, throws a
L<DBIO::Exception>. Without either, a namespace of its own is named from a
random suffix.

=head2 namespace

The name of the namespace this run works in: the one it created, or the
C<existing_namespace> it was given.

=head2 databases

The arrayref of database names this run deploys.

=head2 api

The L<Kubernetes::REST> client built from the kubeconfig.

=head2 kubeconfig

Path of the kubeconfig file in use.

=head2 uses_existing_namespace

True when the instance was built with C<existing_namespace>: it works in a
namespace it did not create and will not delete. See L</NAMESPACES>.

=head2 created_objects

    my @objects = $k8s->created_objects;   # ({ kind => 'Pod', name => '...' }, ...)

The objects this run has created and not yet deleted, in creation order, each
as a hashref with C<kind> and C<name>. An object is listed once the API has
accepted it, so the list is what L</cleanup> will remove -- and what is left
behind when C<cleanup> is not called.

=head2 deploy_databases

    $k8s->deploy_databases;

Creates the namespace (unless it is an C<existing_namespace>) and one pod and
one C<ClusterIP> service per database, every one with a cpu and memory limit
(see L</RESOURCE LIMITS>). Each object is recorded as it is created, so
L</cleanup> can remove it even when this call dies halfway. Returns once the
objects are created; use L</wait_for_ready> to wait for the pods.

=head2 wait_for_ready

    $k8s->wait_for_ready( timeout => 120, interval => 3 );

Polls each database pod until its C<Ready> condition is true. C<timeout>
(seconds, default 120) is one deadline for all databases together;
C<interval> (default 3) is the sleep between polls. Croaks when
L</deploy_databases> was not called first, and on timeout. A failure to read
a pod other than "not there yet" is thrown, not waited out.

=head2 connection_info

    my $info = $k8s->connection_info( mode => 'local' );
    # { pg => { dsn, user, pass, host, port }, ... }

Returns a hashref, keyed by database name, of what a test needs to connect.
C<mode> is C<local> (the default: C<127.0.0.1> and the port
L</setup_port_forwards> chose, which croaks if that was not called) or
C<cluster> (the service's cluster DNS name and its own port, for a runner
inside the cluster).

=head2 env_vars

    my %env = $k8s->env_vars( mode => 'local' );

Flattens L</connection_info> into the C<DBIO_TEST_*_DSN>, C<_USER> and
C<_PASS> environment variables the driver test suites read. Takes the same
C<mode> option.

=head2 setup_port_forwards

    $k8s->setup_port_forwards;

Starts one C<kubectl port-forward> per database to a free local port, for
C<local> mode. Croaks unless L</deploy_databases> and L</wait_for_ready> came
first, and when a forward died within its first two seconds. The processes are
stopped by L</cleanup> (and, as a last resort, when the object is destroyed).

=head2 deploy_test_job

    my $job = $k8s->deploy_test_job(
        image      => 'dbio-test:latest',
        prove_args => ['-l', 't/'],
        resources  => { requests => {...}, limits => {...} },
    );

Creates a Job that runs C<prove> inside the cluster against the databases in
C<cluster> mode and returns its name. C<resources> follows
L</RESOURCE LIMITS>: it must set a cpu and a memory limit or the call throws.

=head2 wait_for_job

    my $exit = $k8s->wait_for_job( name => $job, timeout => 3600, interval => 5 );

Polls the Job until it has succeeded (returns 0) or failed (returns 1).
C<name> defaults to this run's job. Croaks on timeout.

=head2 fetch_job_logs

    my $logs = $k8s->fetch_job_logs( name => $job );
    # [ { pod => $name, log => $text }, ... ]

Returns the log of each pod the Job ran, read with C<kubectl logs>.

=head2 cleanup

    $k8s->cleanup;

Stops the port-forwards and deletes what this run created: its own namespace,
or, in an existing namespace, each recorded object and nothing else. A delete
that fails warns and leaves the object in C<created_objects>. Safe to call
after a failed C<deploy_databases>, and more than once.

=head1 NAMESPACES

A run works in one namespace, and the constructor is told which kind it is.
It is never inferred from what the cluster happens to permit.

=over 4

=item * B<A namespace of its own> -- the default

Without a namespace argument a name C<dbio-test-XXXXXXXX> is generated;
C<< namespace => $name >> names it instead. C<deploy_databases> creates the
namespace, and C<cleanup> deletes it, which takes everything in it along.
This needs a cluster account that may create and delete namespaces. Objects
carry plain names: a pod C<pg> behind a service C<pg-svc>, a job
C<dbio-test-runner>.

=item * B<An existing namespace> -- C<< existing_namespace => $name >>

For an account that is confined to one namespace, usually shared with other
workloads. No namespace is created and none is ever deleted. Because the
namespace is not this run's alone, three things differ:

Every object name carries the id of the run: a pod
C<dbio-test-XXXXXXXX-pg> behind a service C<dbio-test-XXXXXXXX-pg-svc>, a job
C<dbio-test-XXXXXXXX-runner>.

Pods carry only the labels C<dbio-test-run> (the run id) and C<dbio-test-db>
(the database name), and each service selects on both. Services and the job
carry the label C<dbio-test-run> as well, so that it finds every object of a
run. No selector written
for another workload in the namespace matches these pods, so no service that
was there before starts routing to them, and two runs at once do not see each
other's pods.

C<cleanup> deletes exactly the objects this run created, each by kind and
name, as recorded when the API accepted it -- never by label selector.

=back

C<namespace> and C<existing_namespace> together throw. In both kinds C<cleanup>
works from what was recorded at creation, so it also clears up after a
C<deploy_databases> that died halfway; C<created_objects> returns that record.

The databases are reached the same way in both kinds: a C<ClusterIP> service
per database, port-forwarded to a free local port by C<setup_port_forwards>,
or addressed by its cluster DNS name in C<cluster> mode.

=head1 RESOURCE LIMITS

Every container this module creates carries a C<resources> block with both
C<requests> and C<limits>, and the limits always constrain B<cpu and memory>.
Test databases routinely run on small shared machines next to other services;
an unlimited container that is forgotten about can starve or OOM the whole
host, so the unlimited shape is not reachable from here.

The default envelope is C<250m>/C<256Mi> requested, C<1> core / C<1Gi>
limited, matching the checked-in manifests of the driver distributions.

Database pods always get this default envelope: the database specs are built
in, and none of them sets a C<resources> of its own. C<deploy_test_job>
accepts a C<resources> option to raise the ceiling for the test runner:

    resources => {
        requests => { cpu => '500m', memory => '512Mi' },
        limits   => { cpu => '2',    memory => '4Gi'   },
    },

A supplied C<resources> that does not set both a cpu and a memory limit is a
hard error, not a silent fallback to the default: asking for an unlimited (or
half-limited) container is treated as a mistake worth stopping for.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
