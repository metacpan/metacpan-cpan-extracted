package Tests::Service::Base;

use strict;
use warnings;

use Test::Class;
use Test::More;
use base 'Test::Class';

use Beekeeper::Client;
use Beekeeper::Config;
use Beekeeper::Service::Supervisor;
use Time::HiRes 'sleep';

our $DEBUG = 0;

=head1 Tests::Beekeeper::Service

Base class for testing services.

=item start_workers ( $worker_class, %config )

Creates a temporary pool of workers in order to test the service.

Note that tests will fail if $worker_class was already used (as in 'use Foo::Worker')
as a proper service client must not depend at all of worker code.

=item stop_workers

Stop all workers. Called automatically when the test ends.

=cut

use Tests::Service::Config;

my $Supervisor_pid;
my $Toybroker_pid;
my %Worker_pids;

sub using_toybroker {
    return $Toybroker_pid ? 1 : 0;
}

sub automated_testing {
    return ($ENV{'AUTOMATED_TESTING'} || $ENV{'PERL_BATCH'}) ? 1 : 0;
}

sub _sleep {
    my ($self, $time) = @_;
    # Run tests really slow on limited hardware of smoke testers
    $time *= 10 if $self->automated_testing;
    sleep $time;
}

sub check_01_supported_os : Test(startup => 1) {
    my $self = shift;

    unless ($^O eq 'linux') {
        $self->BAILOUT("OS unsupported");
    }

    ok( 1, "Supported OS ($^O)");
}

sub check_02_broker_connection : Test(startup => 1) {
    my $self = shift;
    my $server;
    my $error;

    local $SIG{'__WARN__'} = sub { $error = @_ };

    unless ($self->automated_testing) {

        # Try to connect to broker
        my $config = Beekeeper::Config->get_bus_config( bus_id => 'test' );
        my $bus = Beekeeper::MQTT->new( %$config, timeout => 1 );

        my $broker_host = eval { 
            $bus->connect( blocking => 1 );
            $bus->{server_prop}->{host}; 
        };

        # Disconect now, otherwise forked workers will inherit this connection
        $bus->disconnect if $broker_host;
        %$bus = (); undef $bus;

        if ($broker_host) {
            ok( 1, "Running tests on MQTT broker at $broker_host");
            return;
        }
    }

    # If no real broker is available, spawn a ToyBroker
    $Toybroker_pid = $self->_spawn_worker('Beekeeper::Service::ToyBroker::Worker');

    # Wait a bit until ToyBroker is ready
    $self->_sleep( 0.5 );

    my $is_running = kill(0, $Toybroker_pid);

    unless ($is_running) {
        # Probably address already in use by another broker or a ToyBroker zombie
        $self->stop_all_workers;
        $self->FAIL_ALL("Could not start ToyBroker, no MQTT broker available to run tests");
    }

    ok( 1, "Running tests on ToyBroker");
}

sub stop_test_workers : Test(shutdown) {
    my $self = shift;

    # Stop forked workers when test ends
    $self->stop_all_workers;
}

sub start_workers {
    my ($self, $worker_class, %config) = @_;

    my $workers_count = $config{'workers_count'} ||= 2;
    my $no_wait = delete $config{'no_wait'};

    unless ($Supervisor_pid) {

        ## First call  

        my $supervisor_class = 'Beekeeper::Service::Supervisor::Worker';

        $SIG{'USR2'} = sub {
            # Send by child when supervisor does not compile
            $self->stop_all_workers;
            $self->FAIL_ALL("Could not start supervisor: $supervisor_class does not compile");
        };

        # Spawn a supervisor
        $Supervisor_pid = $self->_spawn_worker( $supervisor_class, foreground => 0 ); #TODO: does not quit on foreground

        # Wait until supervisor is running
        $self->_sleep( 0.5 );

        # Verify that it is running
        my $status = eval { 
            Beekeeper::Service::Supervisor->get_services_status( 
                class   => $supervisor_class,
                timeout => 1,
            );
        };
        unless ($status && $status->{$supervisor_class}->{count}) {
            $self->stop_all_workers;
            $self->FAIL_ALL("Could not start supervisor");
        }
    }

    $SIG{'USR2'} = sub {
        # Send by childs when workers do not compile
        $self->stop_all_workers;
        $self->FAIL_ALL("Could not start workers: $worker_class does not compile");
    };

    my $already_running = grep { $_ eq $worker_class } values %Worker_pids;
    my @started_pids;

    # Spawn workers
    for (1..$workers_count) {

        my $pid = $self->_spawn_worker($worker_class, %config);

        $Worker_pids{$pid} = $worker_class;
        push @started_pids, $pid;

        $self->_sleep( 0.1 );
    }

    unless ($no_wait) {

        # Wait until workers are running
        diag "Waiting for $workers_count $worker_class workers" if $DEBUG;

        my $max_wait = 20;
        while ($max_wait--) {
            $self->_sleep( 0.1 );
            my $status = Beekeeper::Service::Supervisor->get_services_status(
                class   => $worker_class,
                timeout => 1,
            );
            my $running = $status->{$worker_class}->{count} || 0;
            last if $running == $workers_count + $already_running;
        }

        unless ($max_wait > 0) {
            $self->stop_all_workers;
            $self->FAIL_ALL("Failed to start $workers_count workers $worker_class");
        }
    }

    return @started_pids;
}

sub stop_all_workers {
    my $self = shift;

    $self->stop_workers('INT', keys %Worker_pids) if keys %Worker_pids;
    $self->stop_workers('INT', $Supervisor_pid)   if $Supervisor_pid;
    $self->stop_workers('INT', $Toybroker_pid)    if $Toybroker_pid;
}

my $leaving;

sub stop_workers {
    my ($self, $signal, @pids) = @_;

    # Signal workers to quit
    foreach my $worker_pid (@pids) {
        kill($signal, $worker_pid);
    }

    # Wait until test workers are gone
    diag "Waiting for workers to quit" if $DEBUG;
    my $max_wait = 20;
    my @lingering = @pids;
    while (@lingering && $max_wait--) {
        @lingering = grep { kill(0, $_) } @lingering;
        $self->_sleep( 0.1 );
    }

    foreach my $worker_pid (@pids) {
        next if grep { $_ eq $worker_pid } @lingering;
        delete $Worker_pids{$worker_pid};
    }

    if (@lingering) {
        $leaving && return;
        $leaving = 1;
        $self->stop_all_workers;
        $self->FAIL_ALL("Failed to stop workers " . join(', ', values %Worker_pids));
    }
}

sub _spawn_worker {
    my ($self, $worker_class, %config) = @_;

    # Mimic Beekeeper::WorkerPool->spawn_worker

    $SIG{CHLD} = 'IGNORE';

    my $parent_pid = $$;
    my $worker_pid = fork;

    die "Failed to fork: $!" unless defined $worker_pid;

    if ($worker_pid) {
        # Parent stops here
        return $worker_pid;
    }

    # Child

    $SIG{CHLD} = 'IGNORE';
    $SIG{INT}  = 'DEFAULT';
    $SIG{TERM} = 'DEFAULT';
    $SIG{HUP}  = 'DEFAULT';

    srand();

    # Destroy inherithed MQTT connection
    if ($Beekeeper::Client::singleton) {
        $Beekeeper::Client::singleton->{_BUS}->{handle}->destroy;
        undef $Beekeeper::Client::singleton;
    }

    # Load worker module
    eval "use $worker_class";

    if ($@) {
        # Worker does not compile
        warn "ERROR: $worker_class does not compile: " . $@;
        kill('USR2', $parent_pid);
        CORE::exit(99);
    };

    # Mocked pool.config.json config
    my $pool_config = {
         'daemon_name' => 'test-pool',
         'description' => 'Temp pool used for run tests',
         'pool_id'     => 'test-pool',
         'bus_id'      => 'test',
         'workers'     => { },
    };

    # Mocked bus.config.json config
    my $bus_cfg  = Beekeeper::Config->get_bus_config( bus_id => '*' );

    # Mocked worker config
    my $worker_config = {
        log_file => '/dev/null',
        %config
    };

    my $foreground = exists $config{foreground} ? $config{foreground} : $DEBUG;

    eval {

        my $worker = $worker_class->new(
            pool_config => $pool_config,
            bus_config  => $bus_cfg,
            parent_pid  => $parent_pid,
            pool_id     => $pool_config->{pool_id},
            bus_id      => $pool_config->{bus_id},
            config      => $worker_config,
            foreground  => $foreground,
        );

        $worker->__work_forever;
    };

    if ($DEBUG && $@) {
        diag "$worker_class died: $@";
    }

    CORE::exit;
}

1;
