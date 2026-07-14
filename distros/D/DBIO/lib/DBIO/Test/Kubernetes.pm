package DBIO::Test::Kubernetes;
# ABSTRACT: Provision temporary database pods in Kubernetes for DBIO testing
use strict;
use warnings;

use Carp qw(croak);
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

    my $namespace = $args{namespace} // _generate_namespace();
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
        databases       => $databases,
        api             => $api,
        port_forward_pids => [],
        local_ports     => {},
        _deployed       => 0,
        _ready          => 0,
    }, $class;
}

sub namespace  { $_[0]->{namespace} }
sub databases  { $_[0]->{databases} }
sub api        { $_[0]->{api} }
sub kubeconfig { $_[0]->{kubeconfig} }

sub _generate_namespace {
    my @chars = ('a'..'z', '0'..'9');
    my $suffix = join '', map { $chars[rand @chars] } 1..8;
    return "dbio-test-$suffix";
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
        image      => 'mysql:8.0',
        port       => 3306,
        svc_name   => 'mysql-svc',
        env        => [
            { name => 'MYSQL_ROOT_PASSWORD', value => 'dbiotest' },
            { name => 'MYSQL_DATABASE',      value => 'dbio_test' },
        ],
        readiness_cmd => [qw(mysqladmin ping -h localhost)],
        dsn_template  => ( eval { require DBD::MariaDB; 1 }
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

    my $api = $self->api;
    my $ns  = $self->namespace;

    # Create namespace
    print "Creating namespace $ns...\n";
    my $ns_obj = $api->new_object(Namespace =>
        metadata => { name => $ns },
    );
    $api->create($ns_obj);

    # Deploy each database
    for my $db (@{$self->databases}) {
        my $spec = $DB_SPECS{$db} or croak "No spec for database: $db";
        $self->_deploy_db($spec);
    }

    $self->{_deployed} = 1;
}

sub _deploy_db {
    my ($self, $spec) = @_;

    my $api = $self->api;
    my $ns  = $self->namespace;

    print "Deploying $spec->{name} pod...\n";

    # Create Pod
    my $pod = $api->new_object(Pod =>
        metadata => {
            name      => $spec->{name},
            namespace => $ns,
            labels    => { app => $spec->{name}, role => 'dbio-test-db' },
        },
        spec => {
            containers => [{
                name  => $spec->{name},
                image => $spec->{image},
                ports => [{ containerPort => $spec->{port} }],
                env   => $spec->{env},
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
    $api->create($pod);

    # Create Service
    my $svc = $api->new_object(Service =>
        metadata => {
            name      => $spec->{svc_name},
            namespace => $ns,
        },
        spec => {
            selector => { app => $spec->{name} },
            ports    => [{
                port       => $spec->{port},
                targetPort => $spec->{port},
                protocol   => 'TCP',
            }],
        },
    );
    $api->create($svc);
}

# ============================================================================
# READINESS
# ============================================================================

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
            my $pod = eval {
                $api->get('Pod', $db, namespace => $ns);
            };
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
            $host = "$spec->{svc_name}.$ns.svc.cluster.local";
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
        my $local_port = _find_free_port();

        $self->{local_ports}{$db} = $local_port;

        print "Port-forwarding $spec->{svc_name} to 127.0.0.1:$local_port...\n";

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
                "svc/$spec->{svc_name}",
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

    my $api   = $self->api;
    my $ns    = $self->namespace;
    my $image = $opts{image} // 'dbio-test:latest';
    my @args  = @{$opts{prove_args} // ['-l', 't/']};

    # Build env vars for in-cluster mode
    my %env = $self->env_vars(mode => 'cluster');
    my @env_list = map {
        { name => $_, value => $env{$_} }
    } sort keys %env;

    print "Deploying test Job in namespace $ns...\n";

    my $job = $api->new_object(Job =>
        metadata => {
            name      => 'dbio-test-runner',
            namespace => $ns,
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
                    }],
                },
            },
        },
    );
    $api->create($job);

    return 'dbio-test-runner';
}

sub wait_for_job {
    my ($self, %opts) = @_;

    my $job_name = $opts{name} // 'dbio-test-runner';
    my $timeout  = $opts{timeout} // 3600;
    my $interval = $opts{interval} // 5;

    my $api = $self->api;
    my $ns  = $self->namespace;
    my $deadline = time + $timeout;

    print "Waiting for Job $job_name to complete...\n";

    while (time < $deadline) {
        my $job = eval {
            $api->get('Job', $job_name, namespace => $ns);
        };

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

    my $job_name = $opts{name} // 'dbio-test-runner';
    my $api = $self->api;
    my $ns  = $self->namespace;

    # Find pods belonging to the job
    my $pods = $api->list('Pod',
        namespace     => $ns,
        labelSelector => "job-name=$job_name",
    );

    my @logs;
    for my $pod ($pods->items->@*) {
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

    # Delete namespace (cascading delete of all resources)
    if ($self->{_deployed}) {
        my $ns = $self->namespace;
        print "Deleting namespace $ns...\n";
        eval {
            $self->api->delete('Namespace', $ns);
        };
        if ($@) {
            warn "Warning: failed to delete namespace $ns: $@\n";
        }
    }
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

version 0.900002

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

See F<t/kubernetes/smoke.t> for a runnable example.

=head1 DESCRIPTION

L<DBIO::Test::Kubernetes> provisions temporary PostgreSQL and MySQL test
databases inside Kubernetes and exposes the corresponding C<DBIO_TEST_*>
environment variables for local or in-cluster test runs.

It is intended for integration-style test runs that need short-lived database
instances without hand-managed local services or bespoke local containers.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
