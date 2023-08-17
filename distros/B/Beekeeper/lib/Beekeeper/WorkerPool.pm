package Beekeeper::WorkerPool;

use strict;
use warnings;

our $VERSION = '0.10';

use base 'Beekeeper::WorkerPool::Daemon';
use POSIX ":sys_wait_h";
use Time::HiRes 'sleep';
use Beekeeper::Config;

use constant COMPILE_ERROR_EXIT_CODE => 99;


sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(
        daemon_name  => "beekeeper",
        description  => "worker pool",
        get_options  => [ "pool=s", "config-dir=s", "debug" ],
        %args,
    );

    $self->parse_options;

    my $pool_id = $self->{options}->{'pool'} || '';
    ($pool_id) = ($pool_id =~ m/^([\w-]+)$/); # untaint

    unless ($pool_id) {
        print "Mandatory parameter --pool was not specified.\n\n";
        #ENHACEMENT: list available pools
        $self->cmd_help;
        CORE::exit(1);
    }

    $self->{config}->{'pool_id'}   = $pool_id;
    $self->{config}->{daemon_name} = "beekeeper-$pool_id";
    $self->{config}->{description} = "worker pool $pool_id";

    # Pool cannot be started without a proper config file
    $self->load_config || CORE::exit(1);

    unless ($self->{config}->{log_file}) {
        my $file = "$pool_id-pool.log";
        my $dir  = '/var/log';
        my $user = $self->{options}->{'user'} || getpwuid($>);
        ($user) = ($user =~ m/^(\w+)$/); # untaint
        $self->{config}->{log_file} = (-d "$dir/$user") ? "$dir/$user/$file" : "$dir/$file";
    }

    return $self;
}

sub cmd_help {
    my $self = shift;

    my $progname = $0;
    $progname =~ s|.*/||;

    print "Usage: $progname [options] {start|stop|restart|reload|check}\n";
    print " --foreground      Run in foreground (do not daemonize)\n";
    print " --pool       str  Worker pool name (mandatory)\n";
    print " --user       str  Run as specified user\n";
    print " --group      str  Run as specified group\n";
    print " --config-dir str  Path to directory containing config files\n";
    print " --debug           Turn on workers debug flag\n";
    print " --help            Display this help and exit\n";
}

sub load_config {
    my $self = shift;

    my $pool_id  = $self->{config}->{'pool_id'};
    my $conf_dir = $self->{options}->{'config-dir'};

    Beekeeper::Config->set_config_dir($conf_dir) if ($conf_dir);

    my $pool_cfg = Beekeeper::Config->get_pool_config( pool_id => $pool_id );
    my $bus_cfg  = Beekeeper::Config->get_bus_config(  bus_id  => '*' );

    unless ($pool_cfg) {
        die "Worker pool '$pool_id' is not defined into config file pool.config.json\n";
    }

    # Ensure that local bus is defined
    my $bus_id = $pool_cfg->{'bus_id'};

    unless ($bus_cfg->{$bus_id}) {
        die "Bus '$bus_id' is not defined into config file bus.config.json\n";
    }

    # Merge pool.config.json contents
    $self->{config}->{$_} = $pool_cfg->{$_} foreach (keys %$pool_cfg);

    # Keep bus.config.json
    $self->{bus_config} = $bus_cfg;

    # Remove unused inherited entry
    delete $self->{config}->{get_options};

    return 1;
}

sub main {
    my $self = shift;

    my @spawn_queue; # will hold a list of worker classes to be spawned
    my %workers;     # will hold a pid -> class map of running workers

    my $workers_config = $self->{config}->{'workers'};
    my $pool_id        = $self->{config}->{'pool_id'};

    my @spawn_workers = (
        # Every pool spawns a Supervisor worker
        'Beekeeper::Service::Supervisor::Worker',
    );

    if ($self->{config}->{'use_toybroker'}) {
        # Spawn the broker in first place as other workers may depend of it
        unshift @spawn_workers, 'Beekeeper::Service::ToyBroker::Worker';
    }

    foreach my $worker_class (@spawn_workers) {
        $workers_config->{$worker_class} ||= { worker_count => 1 };
    }

    foreach my $worker_class (sort keys %$workers_config) {
        next if grep { $_ eq $worker_class } @spawn_workers;
        push @spawn_workers, $worker_class;
    }

    # Make a list of individual workers to spawn
    foreach my $worker_class (@spawn_workers) {
        my $worker_count = $workers_config->{$worker_class}->{worker_count}  ||
                           $workers_config->{$worker_class}->{workers_count} ;  # compat
        $worker_count = 1 unless defined $worker_count;
        for (1..$worker_count) {
            push @spawn_queue, $worker_class;
        }
    }

    # Very basic log handler (STDERR was already redirected to a log file)
    $SIG{'__WARN__'} = sub {
        my @t = reverse((localtime)[0..5]); $t[0] += 1900; $t[1]++;
        my $tstamp = sprintf("%4d-%02d-%02d %02d:%02d:%02d.000", @t);
        warn "[$tstamp][$$]", @_;
    };

    warn "[info] Pool $pool_id started\n";

    # Install signal handlers to control this daemon and forked workers.
    # The supported signals and related actions are:
    #
    # TERM  tell workers to quit after finishing their current tasks, then quit
    # INT   tell workers to quit immediately (even in the middle of a task), then quit
    # PWR   received when system is being shut down, it is handled the same as TERM
    # HUP   restart workers after finishing their current tasks

    my $mode = '';

    $SIG{TERM} = sub { $mode = 'QUIT_GRACEFULLY'  };
    $SIG{INT}  = sub { $mode = 'QUIT_IMMEDIATELY' };
    $SIG{PWR}  = sub { $mode = 'QUIT_GRACEFULLY'  };
    $SIG{HUP}  = sub { $mode = 'RESTART_POOL' unless $mode };

    # Install a SIGCHLD handler to reap or respawn forked workers. This is
    # executed when one or more subprocess exits, either normally or abnormally.

    $SIG{CHLD} = sub {

        while ((my $worker_pid = waitpid(-1, WNOHANG)) > 0) {

            my $worker_class = $workers{$worker_pid};

            # Mark the worker as defunct
            $workers{$worker_pid} = undef;

            # Handle the edge case of a worker exiting too quickly
            return unless ($worker_class);

            # The wait status of the defunct subprocess ($?) encodes both the
            # actual exit code and the signal which caused the exit, if any.
            my $exit_code = $? >> 8;
            my $signal    = $? & 127;

            if ($exit_code || $signal) {
                warn "[error] $worker_class #$worker_pid exited abormally ($exit_code, $signal)\n"
                    unless ($mode ne '' && $exit_code == 0 && ($signal == 2 || $signal == 15));
            }

            if ($mode eq 'QUIT_IMMEDIATELY' || $mode eq 'QUIT_GRACEFULLY') {
                # Worker terminated just before signaling it to quit.
                # Do not respawn the worker, as we are trying to get rid of it.
                next;
            }
            elsif ($mode eq 'WAIT_CHILDS_TO_QUIT') {
                # Worker terminated after signaling it to quit.
                # Do not respawn it, we are indeed waiting for workers to quit.
                next;
            }
            elsif ($exit_code == COMPILE_ERROR_EXIT_CODE) {
                # Worker does not compile. Do not respawn, it will fail again.
                next;
            }

            # Spawn a worker of the same class that the defuncted one.
            # This is the core functionality of this daemon: when a worker exits
            # for whatever reason, it is immediately replaced by another.
            push @spawn_queue, $worker_class;
        }
    };

    RUN_FOREVER: {

        if ($mode eq 'QUIT_GRACEFULLY') {

            warn "[info] Quitting gracefully...\n";

            # SIGTERM received, propagate signal to all workers to quit gracefully.
            # Then wait until all workers are gone and quit.
    
            $mode = 'WAIT_CHILDS_TO_QUIT';
            kill 'TERM', keys %workers;
        }
        elsif ($mode eq 'QUIT_IMMEDIATELY') {

            warn "[info] Quitting...\n";

            # SIGINT received, propagate signal to all al workers to quit immediately.
            # Then wait until all workers are gone and quit.

            $mode = 'WAIT_CHILDS_TO_QUIT';
            kill 'INT', keys %workers;
        }
        elsif ($mode eq 'RESTART_POOL') {

            warn "[info] Restarting pool\n";

            # SIGHUP received, signal all workers to quit gracefully.
            # Workers will be automatically respawned again.

            $mode = '';
            kill 'TERM', keys %workers;
        }
        elsif ($mode eq 'WAIT_CHILDS_TO_QUIT') {

            # Quit if there are no workers running anymore. This can be 
            # determined because when a worker exits the SIGCHLD handler 
            # removes the corresponding entry into %workers.

            my @still_running = grep { defined $_ } values %workers;

            last RUN_FOREVER unless (@still_running);
        }

        if (@spawn_queue) {

            # @spawn_queue contains the list of workers to be spawned.
            # It is populated at startup, and then by the SIGCHLD handler
            # which adds workers to replace the defuncted ones.

            while (@spawn_queue) {

                # Spawn a new worker and remove it from the queue
                my $worker_class = shift @spawn_queue;
                my $worker_pid = $self->spawn_worker($worker_class);

                unless ($worker_pid) {
                    # Could not fork, try again later
                    unshift @spawn_queue, $worker_class;
                    last;
                }

                # Add to our list of spawned workers (only if it isn't already defunct)
                $workers{$worker_pid} = $worker_class unless (exists $workers{$worker_pid});

                # Give ToyBroker enough time to start accepting connections 
                sleep 0.05 if ($worker_class eq 'Beekeeper::Service::ToyBroker::Worker');
            }

            foreach my $worker_pid (keys %workers) {
                # Remove defunct workers from our list because pids may be reused
                delete $workers{$worker_pid} if (!defined $workers{$worker_pid});
            }
        }

        sleep 1;

        redo RUN_FOREVER;
    }

    warn "[info] Pool $pool_id stopped\n";
}


sub spawn_worker {
    my ($self, $worker_class) = @_;

    my $parent_pid = $$;
    my $worker_pid = fork;

    unless (defined $worker_pid) {
        warn "[error] Failed to fork $worker_class: $!\n";
        return;
    }

    if ($worker_pid) {
        # Parent
        return $worker_pid;
    }

    # Forked child

    $SIG{CHLD} = 'IGNORE';
    $SIG{TERM} = 'DEFAULT';
    $SIG{INT}  = 'DEFAULT';
    $SIG{HUP}  = 'DEFAULT';

    # Ensure that workers don't get the same random numbers
    srand;

    # Load worker codebase
    eval "use $worker_class";

    if ($@) {
        # Worker does not compile
        warn "[error] $worker_class does not compile: " . $@;
        CORE::exit( COMPILE_ERROR_EXIT_CODE );
    };

    unless ($worker_class->can('__work_forever')) {
        # Module compiles fine, but it doesn't seems to be a worker
        warn "[error] $worker_class doesn't know how to __work_forever\n";
        CORE::exit( COMPILE_ERROR_EXIT_CODE );
    }

    my $worker = $worker_class->new(
        parent_pid  => $parent_pid,
        foreground  => $self->{options}->{foreground},
        debug       => $self->{options}->{debug},
        bus_config  => $self->{bus_config},
        pool_config => $self->{config},
        pool_id     => $self->{config}->{'pool_id'},
        bus_id      => $self->{config}->{'bus_id'},
        config      => $self->{config}->{'workers'}->{$worker_class},
    );

    # Destroy daemon object
    %$self = ();
    undef $self;

    $worker->__work_forever;

    CORE::exit;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::WorkerPool - Start, restart or stop worker pools

=head1 VERSION
 
Version 0.09

=head1 SYNOPSIS

  $ bkpr --pool MyPool start
  Starting pool of MyApp workers: beekeeper-MyPool.
  
  $ bkpr --pool MyPool stop
  Stopping pool of MyApp workers: beekeeper-MyPool.
  
  $ bkpr --help
  Usage: bkpr [options] {start|stop|restart|reload|check}
   --foreground      Run in foreground (do not daemonize)
   --pool       str  Worker pool name (mandatory)
   --user       str  Run as specified user
   --group      str  Run as specified group
   --config-dir str  Path to directory containing config files
   --debug           Turn on workers debug flag
   --help            Display this help and exit

=head1 DESCRIPTION

This module contains the core of the command line tool L<bkpr> which is used to
start, restart or stop worker pools of persistent L<Beekeeper::Worker> processes
which receive RPC requests from the message bus.

When started it daemonizes itself (unless C<--foreground> option is passed) and forks
all worker processes, then keeps monitoring those forked processes and immediately
respawns defunct ones.

=head1 CONFIGURATION

=head3 pool.config.json

Workers pools are defined into a file named C<pool.config.json>, which is searched
for into ENV C<BEEKEEPER_CONFIG_DIR>, C<~/.config/beekeeper> and C</etc/beekeeper>.
The file format is relaxed JSON, so it allows comments and trailing commas.

All worker pools running on the host must be declared into this file, specifying 
which logical bus should be used and which services it will run. 

Each entry define a worker pool. Required parameters are:

C<pool_id> An arbitrary identifier for the worker pool.

C<bus_id> An identifier of logical bus used by worker processes.

C<workers> A map of worker classes to (arbitrary) config hashes.

The following example defines "MyApp" as a pool of 2 C<MyApp::Worker> processes:

  [{
      "pool_id" : "MyApp",
      "bus_id"  : "backend",
      "workers" : {
          "MyApp::Worker" : { "worker_count" : 2 },
      },
  }]

=head3 bus.config.json

All logical buses used by an application are defined into a file named 
C<bus.config.json> which specifies the connection parameters to the MQTT brokers
that will service them.

Each entry define a logical bus. Required parameters are:

C<bus_id>: unique identifier of the logical bus (required)

C<bus_role>: specifies if the bus is acting as frontend or backend

C<host>: hostname or IP address of the broker

C<port>: port of the broker (default is 1883)

C<tls>: if set to true enables the use of TLS on broker connection

C<username>: username used to connect to the broker

C<password>: password used to connect to the broker


The following example defines the logical bus "backend":

  [{
      "bus_id" : "backend",
      "host"   : "10.0.0.1",
      "user"   : "username",
      "pass"   : "password",
  }]

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2023 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
