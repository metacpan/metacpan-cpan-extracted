package Acme::Ghost::Prefork;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Ghost::Prefork - Pre-forking ghost daemon

=head1 SYNOPSIS

    use Acme::Ghost::Prefork;

    my $g = Acme::Ghost::Prefork->new(
        logfile => '/tmp/daemon.log',
        pidfile => '/tmp/daemon.pid',
        spirit => sub {
            my $self = shift;
            my $max = 10;
            my $i = 0;
            while ($self->tick) {
                $i++;
                sleep 1;
                $self->log->debug(sprintf("$$> %d/%d", $i, $max));
                last if $i >= $max;
            }
        },
    );

    exit $g->ctrl(shift(@ARGV) // '');

=head1 DESCRIPTION

Pre-forking ghost daemon (server)

=head1 ATTRIBUTES

This class inherits all attributes from L<Acme::Ghost> and implements the following new ones

=head2 graceful_timeout

    graceful_timeout => 120

The maximum amount of time in seconds stopping a spirit gracefully may take before being forced to stop

B<Note that> this value should usually be a little larger than the maximum
amount of time you expect any one request to take

Defaults to C<120>

=head2 heartbeat_interval

    heartbeat_interval => 5

Heartbeat interval in seconds, defaults to C<5>

=head2 heartbeat_timeout

    heartbeat_timeout => 50

Maximum amount of time in seconds before a spirit without a heartbeat will be stopped gracefully

B<Note that> this value should usually be a little larger than the maximum
amount of time you expect any one operation to block the event loop

Defaults to C<50>

=head2 spare

    spare => 2

Temporarily spawn up to this number of additional spirits if there is a need

This allows for new spirits to be started while old ones are still shutting down gracefully,
drastically reducing the performance cost of spirit restarts.

Defaults to C<2>

=head2 spirits, workers

    spirits => 4

Number of spirit processes.

A good rule of thumb is two spirit processes per CPU core for applications that perform mostly
non-blocking operations.
Blocking operations often require more amount of spirits and benefit from decreasing concurrency
(often as low as C<1>)

Defaults to C<4>

=head1 METHODS

This class inherits all methods from L<Acme::Ghost> and implements the following new ones

=head2 again

This method is called immediately after creating the instance and returns it

B<NOTE:> Internal use only!

=head2 healthy

    my $healthy = $g->healthy;

This method returns the number of currently active live spirit processes (with a heartbeat)

=head2 startup

    $prefork->startup;

This method starts preforked process (manager and spirits) and wait for L</"MANAGER SIGNALS">

=head2 tick

    my $ok = $g->tick;
    my $ok = $g->tick(1); # marks the finished status

This is B<required> method of spirit main process that sends heartbeat message to
process manager and returns the status of the running server via the 'ok' attribute

=head1 MANAGER SIGNALS

The manager process can be controlled at runtime with the following signals

=head2 INT, TERM

Shut down server immediately

=head2 QUIT

Shut down server gracefully

=head2 TTIN

Increase spirit pool by one

=head2 TTOU

Decrease spirit pool by one

=head1 SPIRIT SIGNALS

The spirit processes can be controlled at runtime with the following signals

=head2 QUIT

Stop spirit gracefully

=head1 HOOKS

This class inherits all hooks from L<Acme::Ghost> and implements the following new ones

Any of the following methods may be implemented (overwriting) in your class

=head2 finish

    sub finish {
        my $self = shift;
        my $graceful = shift;
        # . . .
    }

Is called when the server shuts down

    sub finish {
        my $self = shift;
        my $graceful = shift;
        $self->log->debug($graceful ? 'Graceful server shutdown' : 'Server shutdown');
    }

=head2 heartbeat

    sub heartbeat {
        my $self = shift;
        my $pid = shift;
        # . . .
    }

Is called when a heartbeat message has been received from a spirit

    sub heartbeat {
        my $self = shift;
        my $pid = shift;
        $self->log->debug("Spirit $pid has a heartbeat");
    }

=head2 reap

    sub reap {
        my $self = shift;
        my $pid = shift;
        # . . .
    }

Is called when a child process (spirit) finished

    sub reap {
        my $self = shift;
        my $pid = shift;
        $self->log->debug("Spirit $pid stopped");
    }

=head2 spawn

    sub spawn {
        my $self = shift;
        my $pid = shift;
        # . . .
    }

Is called when a spirit process is spawned

    sub spawn {
        my $self = shift;
        my $pid = shift;
        $self->log->debug("Spirit $pid started");
    }

=head2 waitup

    sub waitup {
        my $self = shift;
        # . . .
    }

Is called when the manager starts waiting for new heartbeat messages

    sub waitup {
        my $self = shift;
        my $spirits = $prefork->{spirits};
        $self->log->debug("Waiting for heartbeat messages from $spirits spirits");
    }

=head2 spirit

B<The spirit body>

This hook is called when the spirit process has started and is ready to run in isolation.
This is main hook that MUST BE implement to in user subclass

    sub spirit {
        my $self = shift;
        # . . .
    }

=head1 EXAMPLES

=over 4

=item prefork_acme.pl

Prefork acme example of daemon with reloading demonstration

    my $g = MyGhost->new(
        logfile => 'daemon.log',
        pidfile => 'daemon.pid',
    );
    exit $g->ctrl(shift(@ARGV) // 'start');

    1;

    package MyGhost;

    use parent 'Acme::Ghost::Prefork';
    use Data::Dumper qw/Dumper/;

    sub init {
        my $self = shift;
        $SIG{HUP} = sub { $self->hangup };
    }
    sub hangup {
        my $self = shift;
        $self->log->debug(Dumper($self->{pool}));
    }
    sub spirit {
        my $self = shift;
        my $max = 10;
        my $i = 0;
        while ($self->tick) {
            $i++;
            sleep 1;
            $self->log->debug(sprintf("$$> %d/%d", $i, $max));
            last if $i >= $max;
        }
    }

    1;

=item prefork_ioloop.pl

L<Mojo::IOLoop> example

    my $g = MyGhost->new(
        logfile => 'daemon.log',
        pidfile => 'daemon.pid',
    );
    exit $g->ctrl(shift(@ARGV) // 'start');

    1;

    package MyGhost;

    use parent 'Acme::Ghost::Prefork';
    use Mojo::IOLoop;
    use Data::Dumper qw/Dumper/;

    sub init {
        my $self = shift;
        $self->{loop} = Mojo::IOLoop->new;
    }
    sub spirit {
        my $self = shift;
        my $loop = $self->{loop};
        my $max = 10;
        my $i = 0;

        # Add a timers
        my $timer = $loop->timer(5 => sub {
            my $l = shift; # loop
            $self->log->info("Timer!");
        });

        my $recur = $loop->recurring(1 => sub {
            my $l = shift; # loop
            $l->stop unless $self->tick;
            $self->log->debug(sprintf("$$> %d/%d", ++$i, $max));
            $l->stop if $i >= $max;
        });

        $self->log->debug("Start IOLoop");

        # Start event loop if necessary
        $loop->start unless $loop->is_running;

        $self->log->debug("Finish IOLoop");
    }

    1;

=back

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acme::Ghost>, L<Mojo::Server::Prefork>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

use parent qw/Acme::Ghost/;

use Carp qw/carp croak/;
use POSIX qw/WNOHANG/;
use Time::HiRes qw//;
use Scalar::Util qw/weaken/;
use IO::Poll qw/POLLIN POLLPRI/;

use constant {
    DEBUG   => !!($ENV{ACME_GHOST_PREFORK_DEBUG} || 0),
    SPARE   => 2,
    SPIRITS => 4,
    HEARTBEAT_INTERVAL  => 50,
    HEARTBEAT_TIMEOUT   => 5,
    GRACEFUL_TIMEOUT    => 120,
};

sub again {
    my $self = shift;
    my %args = @_;

    # Prefork management subsystem
    $self->{pool}               = {}; # pid => {...}
    $self->{running}            = 0; # 0 - not running; 1 - running
    $self->{finished}           = 0; # 1 - marker for spirits and manager stopping
    $self->{gracefully_stop}    = 0; # 1 - marker for gracefully stopping
    $self->{reader}             = undef; # Readable pipe to get messages from spirits
    $self->{writer}             = undef; # Writable pipe to send messages to manager
    $self->{spare}              = $args{spare} || SPARE;
    $self->{spirits}            = $args{spirits} || $args{workers} || SPIRITS;
    $self->{heartbeat_interval} = $args{heartbeat_interval} || HEARTBEAT_INTERVAL;
    $self->{heartbeat_timeout}  = $args{heartbeat_timeout} || HEARTBEAT_TIMEOUT;
    $self->{graceful_timeout}   = $args{graceful_timeout} || GRACEFUL_TIMEOUT;
    $self->{spirit_cb}          = $args{spirit};

    return $self;
}
sub startup {
    my $self = shift;

    # Pipe for spirit communication
    pipe($self->{reader}, $self->{writer}) or croak("Can't create pipe: $!\n");

    # Set manager signals
    local $SIG{INT}  = local $SIG{TERM} = sub { $self->_stop };
    local $SIG{QUIT} = sub { $self->_stop(1) };
    local $SIG{CHLD} = sub { while ((my $pid = waitpid -1, WNOHANG) > 0) { $self->_stopped($pid) } };
    local $SIG{TTIN} = sub { $self->_increase };
    local $SIG{TTOU} = sub { $self->_decrease };

    # Starting
    $self->log->info("Manager $$ started");
    $self->{running} = 1;
    $self->_manage while $self->{running};
    $self->log->info("Manager $$ stopped");
}
sub healthy {
    return scalar grep { $_->{healthy} } values %{shift->{pool}};
}
sub tick { # Spirit level
    my $self = shift;
    my $finished = shift || 0; # 0 - no finished; 1 - finished
    $self->_heartbeat($finished);
    return $self->ok;
}

# User hooks
sub finish { }      # Emitted when the server shuts down
sub heartbeat { }   # Emitted when a heartbeat message has been received from a spirit
sub reap { }        # Emitted when a child process exited
sub spawn { }       # Emitted when a spirit process is spawned
sub waitup { }      # Emitted when the manager starts waiting for new heartbeat messages
sub spirit {
    my $self = shift;
    my $cb = $self->{spirit_cb};
    return unless $cb;
    return $self->$cb if ref($cb) eq 'CODE';
    $self->log->error("Callback `spirit` is incorrect");
    $self->tick(1);
}

# Internal methods
sub _increase { # Manager level
    my $self = shift;
    $self->log->debug(sprintf("> Increase spirit pool by one")) if DEBUG;
    $self->{spirits} = $self->{spirits} + 1;
}
sub _decrease { # Manager level
    my $self = shift;
    $self->log->debug(sprintf("> Decrease spirit pool by one")) if DEBUG;
    return unless $self->{spirits} > 0;
    $self->{spirits} = $self->{spirits} - 1;

    # Set graceful time for first found unfinished pid (spirit)
    for my $w (values %{$self->{pool}}) {
        unless ($w->{graceful}) {
            $w->{graceful} = Time::HiRes::time;
            last;
        }
    }
}
sub _stop { # Manager level
    my ($self, $graceful) = @_;
    $self->log->debug(sprintf("> Received stop signal/command: %s",
        $graceful ? 'graceful shutdown' : 'forced shutdown')) if DEBUG;
    $self->finish($graceful);
    $self->{finished} = 1;
    $self->{gracefully_stop} = $graceful ? 1 : 0;
}
sub _stopped { # Manager level (Calls when a child process exited)
    my $self = shift;
    my $pid = shift;
    $self->log->debug(sprintf("> Reap %s", $pid)) if DEBUG;
    $self->reap($pid);

    return unless my $w = delete $self->{pool}{$pid};
    $self->log->info("Spirit $pid stopped");
    unless ($w->{healthy}) {
        $self->log->error("Spirit $pid stopped too early, shutting down");
        $self->_stop;
    }
}
sub _manage { # Manager level
    my $self = shift;

    # Spawn more spirits if necessary
    if (!$self->{finished}) { # No finished
        my $graceful = grep { $_->{graceful} } values %{$self->{pool}}; # Number gracefuled spirits
        my $spare = $self->{spare};
           $spare = $graceful # Check gracefuls
                ? $graceful > $spare # Check difference between graceful numbers and spare numbers
                    ? $spare # graceful numbers greater than spare numbers - use original spare value
                    : $graceful # graceful numbers less or equal to spare numbers - set spare to graceful
                : 0; # No gracefuls - no spares - set spare to 0 ('spare = 0')
        my $required = ($self->{spirits} - keys %{$self->{pool}}) + $spare; # How many spirits are required?
        $self->log->debug(sprintf("> graceful=%d; spare=%d; need=%d", $graceful, $spare, $required))
            if DEBUG && $required;
        $self->_spawn while $required-- > 0; # Spawn required spirits
    } elsif (!keys %{$self->{pool}}) { # No PIDs found, shutdown!
        return delete $self->{running}; # Return from the manager and exit immediately
    }

    # Wait for heartbeats
    $self->_wait;

    # Stops
    my $interval = $self->{heartbeat_interval};
    my $hb_to    = $self->{heartbeat_timeout};
    my $gf_to    = $self->{graceful_timeout};
    my $now      = Time::HiRes::time;
    my $log      = $self->log;
    for my $pid (keys %{$self->{pool}}) {
        next unless my $w = $self->{pool}{$pid}; # Get spirit struct

        # No heartbeat (graceful stop)
        if (!$w->{graceful} && ($w->{time} + $interval + $hb_to <= $now)) {
            $log->error("Spirit $pid has no heartbeat ($hb_to seconds), restarting");
            $w->{graceful} = $now;
        }

        # Graceful stop with timeout
        my $graceful = $w->{graceful} ||= $self->{gracefully_stop} ? $now : undef;
        if ($graceful && !$w->{attempt}) {
            $w->{attempt}++;
            $log->info("Stopping spirit $pid gracefully ($gf_to seconds)");
            kill 'QUIT', $pid or $self->_stopped($pid);
        }
        $w->{force} = 1 if $graceful && $graceful + $gf_to <= $now; # The conditions for a graceful stop by timeout were violated

        # Normal stop
        if ($w->{force} || ($self->{finished} && !$graceful)) {
            $log->warn("Stopping spirit $pid immediately");
            kill 'KILL', $pid or $self->_stopped($pid);
        }
    }
}
sub _spawn { # Manager level (Spawn a spirit and transferring control to it)
    my $self = shift;

    # Manager
    croak("Can't fork: $!\n") unless defined(my $pid = fork);
    if ($pid) { # Parent (manager)
        $self->spawn($pid);
        return $self->{pool}{$pid} = {time => Time::HiRes::time};
    }
    $self->{spirited} = 1; # Inspiration! (disables cleanup)

    weaken $self;

    # Clean spirit signals
    $SIG{$_} = 'DEFAULT' for qw/CHLD INT TERM TTIN TTOU/;

    # Set QUIT signal
    $SIG{QUIT} = sub {
        $self->log->warn("Spirit $$ received QUIT signal") if DEBUG;
        $self->_heartbeat(1); # Send finish command to manager
    };

    # Close reader pipe
    delete $self->{reader};

    # Reset the random number seed for spirit
    srand;

    $self->log->info("Spirit $$ started");

    # Start spirit
    $self->spirit;

    exit 0; # EXIT FROM APPLICATION
}
sub _wait { # Manager level
    my $self = shift;

    # Call waitup hook
    $self->waitup;

    # Poll for heartbeats
    my $reader = $self->{reader};
    return unless _is_readable(1000, fileno($reader));
    return unless $reader->sysread(my $chunk, 4194304);

    # Update heartbeats (and stop gracefully if necessary)
    my $now = Time::HiRes::time;
    while ($chunk =~ /(\d+):(\d)\n/g) {
        my $pid = $1;
        my $finished = $2;
        $self->log->warn("Spirit $$ received finished HeartBeat message $pid:$finished") if DEBUG && $finished;
        next unless my $w = $self->{pool}{$pid};
        $w->{healthy} = 1;
        $w->{time} = $now;
        $self->heartbeat($pid);
        if ($finished) { # Oops! Needs to finish
            $w->{graceful} ||= $now;
            $w->{attempt}++;
        }
    }
}

sub _heartbeat { # Spirit level (send message to manager)
    my $self = shift;
    my $msg = shift || 0;
    $self->{ok} = 0 if $msg; # Stop gracefully
    $self->{writer}->syswrite("$$:$msg\n") or exit 0;
}

# See Mojo::Util::_readable
sub _is_readable { !!(IO::Poll::_poll(@_[0, 1], my $m = POLLIN | POLLPRI) > 0) }

1;

__END__
