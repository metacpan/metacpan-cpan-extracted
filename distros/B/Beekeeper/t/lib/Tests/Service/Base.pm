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

use constant DEBUG => 0;

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

my $Broker;
my $supervisor_pid;
my $toybroker_pid;
my @forked_pids;

sub using_toybroker {
    return ($Broker =~ m/ToyBroker/);
}

sub check_01_supported_os : Test(startup => 1) {
    my $class = shift;

    unless ($^O eq 'linux' || $^O eq 'freebsd') {
        BAIL_OUT "OS unsupported";
    }

    ok( 1, "Supported OS ($^O)");
}

sub check_02_broker_connection : Test(startup => 1) {
    my $class = shift;
    my $server;
    my $error;

    local $SIG{'__WARN__'} = sub { $error = @_ };

    # Try to connect to broker
    my $config = Beekeeper::Config->get_bus_config( bus_id => 'test' );
    my $bus = Beekeeper::Bus::STOMP->new( %$config, timeout => 1 );
    $Broker = eval { $bus->connect( blocking => 1 ); $bus->{server} };

    # Disconect now, otherwise forked workers will inherit this connection
    $bus->disconnect( blocking => 1 ) if $Broker;
    %$bus = (); undef $bus;

    if ($Broker) {
        ok( 1, "Can connect to STOMP broker $Broker");
        return;
    }

    # Spawn a ToyBroker
    $toybroker_pid = $class->_spawn_worker('Beekeeper::Service::ToyBroker::Worker');
    $Broker = 'ToyBroker';

    # Wait until ToyBroker is ready
    sleep (($ENV{'AUTOMATED_TESTING'} || $ENV{'PERL_BATCH'}) ? 2 : 0.5 );

    ok( 1, "Using ToyBroker");
}

sub stop_test_workers : Test(shutdown) {
    my $class = shift;

    # Stop forked workers when test ends
    $class->stop_all_workers;
}

sub start_workers {
    my ($class, $worker_class, %config) = @_;

    my $workers_count = $config{'workers_count'} ||= 2;
    my $no_wait = delete $config{'no_wait'};
    my @pids;

    unless ($supervisor_pid) {

        ## First call  

        # Spawn a supervisor
        $supervisor_pid = $class->_spawn_worker('Beekeeper::Service::Supervisor::Worker');

        # Wait until supervisor is running (this blocks for few seconds)
        diag "Waiting for supervisor" if DEBUG;
        my $max_wait = 100;
        while ($max_wait--) {
            my $status = Beekeeper::Service::Supervisor->get_services_status( class => 'Beekeeper::Service::Supervisor::Worker' );
            my $running = $status->{'Beekeeper::Service::Supervisor::Worker'}->{count} || 0;
            last if $running == 1;
            Time::HiRes::sleep(0.1);
        }

        $SIG{'USR2'} = sub {
            # Send by childs when worker does not compile
            $class->BAILOUT("$worker_class does not compile");
        };
    }

    # Spawn workers
    for (1..$workers_count) {
        my $pid = $class->_spawn_worker($worker_class, %config);
        push @forked_pids, $pid;
        push @pids, $pid;
    }

    return @pids if $no_wait;

    # Wait until workers are running
    diag "Waiting for $workers_count $worker_class workers" if DEBUG;
    my $max_wait = 100;
    while ($max_wait--) {
        my $status = Beekeeper::Service::Supervisor->get_services_status( class => $worker_class );
        my $running = $status->{$worker_class}->{count} || 0;
        last if $running == $workers_count;
        Time::HiRes::sleep(0.1);
    }

    return @pids;
}

sub stop_all_workers {
    my $class = shift;

    $class->stop_workers('INT', @forked_pids);
    $class->stop_workers('INT', $supervisor_pid) if $supervisor_pid;
    $class->stop_workers('INT', $toybroker_pid) if $toybroker_pid;
}

sub stop_workers {
    my ($class, $signal, @pids) = @_;

    # Signal workers to quit
    foreach my $worker_pid (@pids) {
        kill($signal, $worker_pid);
    }

    # Wait until test workers are gone
    diag "Waiting for workers to quit" if DEBUG;
    my $max_wait = 100;
    while (@pids && $max_wait--) {
        @pids = grep { kill(0, $_) } @pids;
        Time::HiRes::sleep(0.1);
    }
};

sub _spawn_worker {
    my ($class, $worker_class, %config) = @_;

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

    # Destroy inherithed STOMP connection
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
        #TODO: send log to a temp file, so it can be inspected 
        log_file => '/dev/null',
        %config
    };

    my $foreground = $config{foreground} || DEBUG;

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

    CORE::exit;
}

1;
