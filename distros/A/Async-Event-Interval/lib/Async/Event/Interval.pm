package Async::Event::Interval;

use warnings;
use strict;

our $VERSION = '1.14';

use Carp qw(croak);
use Data::Dumper;
use IPC::Shareable qw(:lock);
use Parallel::ForkManager;
use POSIX ();
use Time::HiRes ();

use constant {
    # Number of tries to create the %events cache
    SHM_CREATE_RETRIES      => 100,

    # Seconds to allow a deadlock cleanup in _end() 
    END_LOCK_TIMEOUT        => 2,

    # Allow TERM signal to work for this many seconds before KILL
    STOP_TERM_TIMEOUT       => 0.5,

    # Seconds between checks to verify that stop signal worked
    STOP_KILL_POLL_INTERVAL => 0.05,

    # Allow KILL signal to work for this many seconds before croaking
    STOP_KILL_TIMEOUT       => 1,
};

$SIG{CHLD} = 'IGNORE';

for my $sig (qw(INT TERM)) {
    $SIG{$sig} = sub {
        _end(1);
        $SIG{$sig} = 'DEFAULT';
        kill $sig, $$;
    };
}

# Every access to the %events hash MUST go through _events_read() for reads, and
# _events_write() for writes. This ensures all struct access uses proper locking
# and remains atomic. See new() as an example of how they are used.

my %events;

my $shared_memory_protect_lock = _rand_shm_lock();
_create_events_segment();
my $creator_pid = $$;
my $_shutting_down = 0;

# Fallback PID list for _end() when %events lock is stuck
my @all_pids;

*restart = \&start;

sub new {
    my $self = bless {}, shift;

    _events_write(sub {
        $events{_id_counter} //= 0;
        $events{_event_count} //= 0;
        my $id = $events{_id_counter}++;
        $events{_event_count}++;
        $self->id($id);
        $events{$id} = { error => 0 };
    });

    $self->_pm;
    $self->_setup(@_);
    $self->_started(0);

    return $self;
}
sub error {
    my ($self) = @_;
    $self->_detect_crash;
    return $self->_crashed;
}
sub error_message {
    my ($self) = @_;
    return $self->_error_message;
}
sub errors {
    my ($self) = @_;
    return $self->_errors || 0;
}
sub events {
    return _events_read(sub {
        my %copy;

        for my $id (keys %events) {
            next if $id =~ /^_/;

            my $event = $events{$id};

            my %filtered;

            for my $entry (keys %$event) {
                next if $entry =~ /^_/;
                $filtered{$entry} = $event->{$entry};
            }

            my $pid   = $event->{pid};
            my $error = $event->{error} || 0;

            $filtered{error}   = $error;
            $filtered{waiting} = ($error || ! $pid || ! kill(0, $pid)) ? 1 : 0;

            $copy{$id} = \%filtered;

            if ($copy{$id}{shared_scalars}) {
                $copy{$id}{shared_scalars} = [ @{ $copy{$id}{shared_scalars} } ];
            }
        }
        return \%copy;
    });
}
sub id {
    my ($self, $id) = @_;
    $self->{id} = $id if defined $id;
    return $self->{id};
}
sub immediate {
    my ($self, $value) = @_;

    # We check for param count here, because we do allow undef as a legitimate
    # value

    if (@_ > 1) {
        if (defined $value && $value !~ /^\d+$/) {
            croak "\$value must be a non-negative integer or undef";
        }
        _events_write(sub { $events{$self->id}{immediate} = $value });
    }

    return _events_read(sub { $events{$self->id}{immediate} });
}
sub info {
    my ($self) = @_;
    return _events_read(sub {
        my $event = $events{$self->id} or return undef;

        my %copy;

        for my $entry (keys %$event) {
            next if $entry =~ /^_/;
            $copy{$entry} = $event->{$entry};
        }

        my $pid   = $event->{pid};
        my $error = $event->{error} || 0;

        $copy{error}   = $error;
        $copy{waiting} = ($error || ! $pid || ! kill(0, $pid)) ? 1 : 0;

        if ($copy{shared_scalars}) {
            $copy{shared_scalars} = [ @{$copy{shared_scalars}} ];
        }

        return \%copy;
    });
}
sub interval {
    my ($self, $interval) = @_;

    if (defined $interval) {
        if ($interval !~ /^\d+$/ && $interval !~ /^(?:\d+)?\.\d+$/) {
            croak "\$interval must be an integer or float";
        }
        _events_write(sub { $events{$self->id}{interval} = $interval });
    }

    return _events_read(sub { $events{$self->id}->{interval} });
}
sub pid {
    my ($self) = @_;
    return $self->_pid;
}
sub runs {
    my ($self) = @_;
    return $self->_runs || 0;
}
sub shared_scalar {
    my ($self) = @_;

    my $shm_key;
    my $unique_shm_key_found = 0;
    my $scalar;

    _events_write(sub {
        for (0..9) {
            $shm_key = _rand_shm_key();
            my $existing = $events{$self->id}{shared_scalars} || [];
            if (! grep { $_ eq $shm_key } @$existing) {
                $unique_shm_key_found = 1;
                last;
            }
        }

        return unless $unique_shm_key_found;

        tie $scalar, 'IPC::Shareable', $shm_key, {
            create    => 1,
            destroy   => 1,
            protected => _shm_lock(),
        };

        push @{ $events{$self->id}{shared_scalars} }, $shm_key;
    });

    if (! $unique_shm_key_found) {
        croak("Could not generate a unique shared memory segment.");
    }

    push @{ $self->{_shared_scalars} }, \$scalar;

    return \$scalar;
}
sub start {
    my ($self, @callback_params) = @_;

    if ($self->_started) {
        warn "Event already running...\n";
        return;
    }

    $self->_crashed(0);

    _events_write(sub {
        delete $events{$self->id}{_stop_requested};
        delete $events{$self->id}{_clean_exit};
        $events{$self->id}{error} = 0;
    });

    $self->_started(1);
    $self->_event(@callback_params);
}
sub status {
    my ($self) = @_;

    $self->_detect_crash;

    return 0 unless $self->_started;

    if (! $self->pid) {
        croak "Event is started, but no PID can be found. This is a " .
              "fatal error. Exiting...\n";
    }

    return $self->pid;
}
sub stop {
    my $self = shift;

    return if $self->_crashed;
    return unless $self->pid;

    $self->_started(0);

    # Set cooperative stop flag so a well-behaved child exits its event loop on
    # the next iteration. The signals below act as a safety net for children
    # stuck in a long-running callback.

    _events_write(sub { $events{$self->id}{_stop_requested} = 1 });

    # Try graceful SIGTERM first so a user-installed SIGTERM handler in the
    # callback can do cleanup (close files, release locks, etc.).

    # Escalate to SIGKILL if the child is still alive after STOP_TERM_TIMEOUT

    # _signal_and_wait polls at STOP_KILL_POLL_INTERVAL and returns 1 as
    # soon as the process is gone, so the common case is a single poll.

    return if $self->_signal_and_wait('TERM', STOP_TERM_TIMEOUT);
    return if $self->_signal_and_wait('KILL', STOP_KILL_TIMEOUT);

    croak "Event stop was called, but the process hasn't been killed " .
          "(SIGTERM + SIGKILL both ignored). This is a fatal event. " .
          "Exiting...\n";
}
sub timeout {
    my ($self, $timeout) = @_;

    # Check param count here because we allow undef as a valid value for
    # $timeout

    if (@_ > 1) {
        if (defined $timeout && $timeout !~ /^\d+$/) {
            croak "\$timeout must be a non-negative integer or undef";
        }
        _events_write(sub { $events{$self->id}{timeout} = $timeout });
    }

    return _events_read(sub { $events{$self->id}->{timeout} });
}
sub wait {
    my ($self, $interval) = @_;

    if (defined $interval) {
        if ($interval !~ /^\d+$/ && $interval !~ /^(?:\d+)?\.\d+$/) {
            croak "\$interval must be an integer or float";
        }
    }
    else {
        $interval = 0.01;
    }

    while (! $self->waiting) {
        select(undef, undef, undef, $interval);
    }

    return;
}
sub waiting {
    my ($self) = @_;
    return 1 if $self->error || ! $self->status;
    return 0;
}

# Internal methods

sub _args {
    my ($self, $args) = @_;

    if (defined $args) {
        $self->{args} = $args;
    }

    return $self->{args};
}
sub _cb {
    my ($self, $cb) = @_;

    if (defined $cb) {
        croak "Callback must be a code reference." if ref $cb ne 'CODE';
        $self->{cb} = $cb;
    }

    return $self->{cb};
}
sub _crashed {
    my ($self, $crashed) = @_;
    $self->{crashed} = $crashed ? 1 : 0 if defined $crashed;
    return $self->{crashed} ? 1 : 0;
}
sub _create_events_segment {
    my $created;
    my $tries = 0;

    while (! $created) {
        if ($tries++ >= SHM_CREATE_RETRIES) {
            croak
                "Unable to create the %events shared memory segment after "
                . SHM_CREATE_RETRIES
                . " attempts: $@";
        }

        $created = eval {
            tie %events, 'IPC::Shareable', {
                key         => _rand_shm_key(),
                create      => 1,
                exclusive   => 1,
                protected   => _shm_lock(),
                mode        => 0600,
                destroy     => 1
            };
            1;
        };
    }

    return $created;
}
sub _detect_crash {
    my ($self) = @_;

    # Initial short-circuits: nothing to detect if the event is already known
    # stopped, or if pid is unset / already cleared.

    return unless $self->_started;
    return unless $self->pid && $self->pid > 0;

    if (! kill 0, $self->pid) {
        $self->_started(0);
        $self->_pid(0);

        if (_events_read(sub { $events{$self->id}{_clean_exit} })) {
            _events_write(sub { delete $events{$self->id}{_clean_exit} });
        }
        else {
            $self->_crashed(1);
            _events_write(sub { $events{$self->id}{error} = 1 });
        }
    }
}
sub _error_message {
    my ($self, $msg) = @_;

    if (defined $msg) {
        _events_write(sub { $events{$self->id}->{error_message} = $msg });
    }
    return _events_read(sub { $events{$self->id}->{error_message} });
}
sub _errors {
    my ($self, $increment) = @_;

    if (defined $increment) {
        _events_write(sub { $events{$self->id}->{errors}++ });
    }
    return _events_read(sub { $events{$self->id}->{errors} });
}
sub _event {
    my ($self, @event_params) = @_;

    my @callback_params = scalar @event_params
        ? @event_params
        : @{ $self->_args };

    local $SIG{__WARN__} = sub {
        my $warn = shift;
        warn $warn if $warn !~ /^child process/;
    };

    # The for() is just a workaround. It only fires a single fork

    for (0..1) {
        my $pid = $self->_pm->start;

        if (! defined $pid) {
            croak "fork() failed: $!";
        }

        if ($pid) {
            # This is the parent process
            $self->_pid($pid);
            push @all_pids, $pid;
            last;
        }

        # Set the child's proc id

        $self->{pid} = $$;

        # If no interval, run only once

        if ($self->interval) {
            eval {
                my $ran_immediate;

                while (1) {
                    if (_events_read(sub { $events{$self->id}{_stop_requested} })) {
                        last;
                    }

                    if (! $ran_immediate && $self->immediate) {
                        $ran_immediate = 1;
                        $self->_run_callback(@callback_params);
                        next;
                    }

                    select(undef, undef, undef, $self->interval);

                    $self->_run_callback(@callback_params);
                }
            };

            my $exit_code = $@ ? 1 : 0;

            if (! $exit_code) {
                _events_write(sub {$events{$self->id}{_clean_exit} = 1});
            }
            else {
                _events_write(sub {$events{$self->id}{error} = 1});
            }

            $self->_pm->finish($exit_code);
        }
        else {
            eval { $self->_run_callback(@callback_params) };

            my $exit_code = $@ ? 1 : 0;

            if (! $exit_code) {
                _events_write(sub {$events{$self->id}{_clean_exit} = 1});
            }
            else {
                _events_write(sub {$events{$self->id}{error} = 1});
            }

            $self->_pm->finish($exit_code);
        }
    }
}
sub _events_read {
    my ($cb) = @_;

    my $knot = tied(%events);

    return $cb->() unless $knot;

    $knot->lock(LOCK_SH);

    my $callback_result;

    my $ok = eval { $callback_result = $cb->(); 1 };
    my $err = $@;

    $knot->unlock;

    die $err if ! $ok;

    return $callback_result;
}
sub _events_write {
    my ($cb) = @_;

    my $knot = tied(%events);

    return $cb->() unless $knot;

    my $callback_result;

    $knot->lock(LOCK_EX, sub {
        $callback_result = $cb->();
    });

    return $callback_result;
}
sub _pid {
    my ($self, $pid) = @_;
    if (defined $pid) {
        $self->{pid} = $pid;
        _events_write(sub { $events{$self->id}->{pid} = $self->{pid} });
    }
    return $self->{pid} || undef;
}
sub _pm {
    my ($self) = @_;

    if (! exists $self->{pm}) {
        $self->{pm} = Parallel::ForkManager->new(1);
    }

    return $self->{pm};
}
sub _rand_shm_key {
    return sprintf('0x%x', int(rand(0x7FFFFFFF)));
}
sub _rand_shm_lock {
    # Used for the 'protected' option in the %events hash creation.
    #
    # IPC::Shareable 1.14+ persists 'protected' in a semaphore slot
    # (SEM_PROTECTED), which the system caps at semvmx (typically 0..32767, and
    # 0 means "unprotected"). Derive a stable, in-range value from $$ so a
    # forked subprocess inherits the same key.

    return 1 + ($$ % 32767);
}
sub _run_callback {
    my ($self, @params) = @_;

    my $timeout = $self->timeout;

    my $ok = eval {
        if ($timeout) {
            my $handler = sub {
                die "Callback timed out after ${timeout} seconds\n"
            };

            local $SIG{ALRM} = $handler;

            # Re-install SIGALRM via POSIX::sigaction with flags=0 to
            # explicitly clear SA_RESTART. Perl's default $SIG{ALRM} setup
            # leaves SA_RESTART on, which causes the kernel to transparently
            # resume select() and other restartable syscalls after SIGALRM —
            # silently swallowing the timeout on Linux (and anywhere SA_RESTART
            # is the default). The local $SIG{ALRM} above still does the
            # safe-signal dispatch to the Perl coderef; sigaction just fixes the
            # kernel flags.

            my $sigset = POSIX::SigSet->new(POSIX::SIGALRM());
            my $sa     = POSIX::SigAction->new($handler, $sigset, 0);
            my $old    = POSIX::SigAction->new();
            POSIX::sigaction(POSIX::SIGALRM(), $sa, $old);

            alarm($timeout);
            $self->_cb->(@params);
            alarm(0);

            POSIX::sigaction(POSIX::SIGALRM(), $old);
        }
        else {
            $self->_cb->(@params);
        }
        1;
    };

    alarm(0) if $timeout;

    if (! $ok) {
        my $err = $@;

        $self->_errors(1);
        $self->_error_message($err);
        $self->_runs(1);
        $self->status;

        die $err;
    }

    $self->_runs(1);
    $self->status;
}
sub _runs {
    my ($self, $increment) = @_;
    if (defined $increment) {
        _events_write(sub { $events{$self->id}->{runs}++ });
    }
    return _events_read(sub { $events{$self->id}->{runs} });
}
sub _setup {
    my ($self, $interval, $cb, @args) = @_;
    $self->interval($interval);
    $self->_cb($cb);
    $self->_args(\@args);
}
sub _shm_lock {
    return $shared_memory_protect_lock;
}
sub _signal_and_wait {
    my ($self, $sig, $timeout) = @_;

    kill $sig, $self->pid;

    my $start = Time::HiRes::time();

    while (kill 0, $self->pid) {
        return 0 if Time::HiRes::time() - $start >= $timeout;
        select(undef, undef, undef, STOP_KILL_POLL_INTERVAL);
    }

    return 1;
}
sub _started {
    my ($self, $started) = @_;
    $self->{started} = $started if defined $started;
    return $self->{started};
}

# External access: These allow unit tests to directly access live data in the
# %events hash

sub _events_count {
    # Number of events currently alive
    return _events_read(sub { $events{_event_count} || 0 });
}
sub _events_knot {
    # The IPC::Shareable knot itself
    return tied(%events);
}
sub _events_next_id {
    # Fetch the next ID that will be assigned to an event
    return _events_read(sub { $events{_id_counter} || 0 });
}
sub _events_stop_requested {
    # Is the _stop_requested flag set?
    my ($self) = @_;
    return _events_read(sub { $events{$self->id}{_stop_requested} });
}

# Destruction

sub _alarmed_eval {
    my ($timeout, $code) = @_;

    my $handler = sub { die "alarm\n" };

    local $SIG{ALRM} = $handler;

    my $sigset = POSIX::SigSet->new(POSIX::SIGALRM());
    my $sa     = POSIX::SigAction->new($handler, $sigset, 0);
    my $old    = POSIX::SigAction->new();

    POSIX::sigaction(POSIX::SIGALRM(), $sa, $old);

    alarm($timeout);
    eval { $code->() };
    alarm(0);

    POSIX::sigaction(POSIX::SIGALRM(), $old);
}
sub _end {
    my ($is_shutdown) = @_;

    return if $$ != $creator_pid;

    if ($is_shutdown) {
        return if $_shutting_down;
        $_shutting_down = 1;
    }

    # Phase 1: Collect PIDs from %events (1 second timeout).
    # Falls back to @all_pids if the lock is stuck.

    my @pids;

    _alarmed_eval(1, sub {
        _events_read(sub {
            for my $id (keys %events) {
                next if $id =~ /^_/;
                my $pid = $events{$id}{pid};
                push @pids, $pid if $pid && kill(0, $pid);
            }
        });
    });

    if (! @pids) {
        @pids = grep { kill(0, $_) } @all_pids;
    }

    # Phase 2: Kill children (bounded by poll loops, no alarm needed).

    for my $pid (@pids) {
        kill 'TERM', $pid;
    }
    for my $pid (@pids) {
        for (1..10) {
            last unless kill(0, $pid);
            select(undef, undef, undef, 0.05);
        }

        kill 'KILL', $pid if kill(0, $pid);
    }

    # Phase 3: Clear %events (1 second timeout).

    _alarmed_eval(1, sub {
        _events_write(sub {
            delete @events{keys %events};
        });
    });

    # Phase 4: Release IPC segments (1 second timeout).
    #
    # IPC::Shareable's STORE on a nested hashref/arrayref creates child
    # segments and calls _remove_child() on the previous value. When a forked
    # child does that during its callback, the parent's global_register still
    # lists the now-dead child segments. clean_up_protected then re-removes
    # them and shmctl() returns EINVAL. The cleanup itself is correct (seg
    # count returns to baseline); only the warning is spurious, so filter it.

    _alarmed_eval(1, sub {
        local $SIG{__WARN__} = sub {
            my $msg = shift;

            return if $msg =~ /Couldn't remove (?:shm segment|semaphore set) \d+: Invalid argument/;
            return if $msg =~ /Use of uninitialized value \$sem_remove_status/;
            return if $msg =~ /Use of uninitialized value \$id in hash element/;

            warn $msg;
        };
        IPC::Shareable::clean_up_protected(_shm_lock());
    });
}
sub DESTROY {
    my $self = $_[0];

    return if $$ != $creator_pid;
    return if $_shutting_down;

    if (defined $self) {
        $self->stop if $self->pid;
    }

    # On events with interval of zero, ForkManager runs finish(), which calls
    # our destroy method. We only want to blow away the %events hash if we truly
    # go out of scope

    return if (caller())[0] eq 'Parallel::ForkManager::Child';

    # Release any shared_scalar segments owned by this event. These are  tracked
    # in $self->{_shared_scalars}, not inside %events, so they can be cleaned up
    # outside the %events lock.

    if ($self->{_shared_scalars}) {
        for my $scalar (@{ $self->{_shared_scalars} }) {
            next unless ref $scalar eq 'SCALAR';
            my $knot = tied $$scalar;
            eval { $knot->remove } if $knot;
        }
    }

    my $ok = eval {
        _events_write(sub {
            delete $events{$self->id};
            $events{_event_count}--;
        });
        1;
    };

    if (! $ok) {
        if (my $knot = tied(%events)) {
            $knot->{_lock} = 0;
        }
    }
}
END {
    _end(1);
}

sub _vim{} # vim navigation marker; intentionally empty

1;

__END__

=head1 NAME

Async::Event::Interval - Scheduled and one-off restartable asynchronous events

=for html
<a href="https://github.com/stevieb9/async-event-interval/actions"><img src="https://github.com/stevieb9/async-event-interval/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/async-event-interval?branch=master'><img src='https://coveralls.io/repos/stevieb9/async-event-interval/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 SYNOPSIS

Here's an example of a simple asynchronous event that fetches JSON data from a
website every two seconds using a shared scalar variable to hold the decoded
JSON hashref, while allowing the main application to continue running in the
foreground. Multiple events can be used simultaneously if desired.

See the L</SCENARIOS/EXAMPLES> section for further usage examples.

    use warnings;
    use strict;

    use Async::Event::Interval;
    use JSON;

    my $event = Async::Event::Interval->new(2, \&callback);

    my $api_data_href = $event->shared_scalar;

    $event->start;

    while (1) {

        if ($$api_data_href) {
            print "Element 1 of 'data' dict is $$api_data_href->{data}[1]\n";
            # ...do other things with data
        }

        # ...do other things

        if ($event->error) {
            print $event->error_message;
            $event->restart;
        }
    }

    sub callback {
        my $api_json = some_web_api_call(); # '{"data": [1, 2, 3]}';
        $$api_data_href = decode_json($api_json);
    }


=head1 DESCRIPTION

Very basic implementation of asynchronous events triggered by a timed interval.
If a time of zero is specified, we'll run the event only once while providing
the ability to re-run it manually at any time in the future.

B<Signal handling>: The module installs C<$SIG{INT}> and C<$SIG{TERM}>
handlers at load time to ensure shared memory segments are cleaned up when the
host process is killed by a signal. The handlers stop any running event
children, remove all shared memory segments, then re-raise the signal with the
default handler so the process exits with the correct status. If you install
your own handlers for these signals, call C<Async::Event::Interval::_end(1)>
from them before exiting to avoid leaking segments.

The module also sets C<$SIG{CHLD} = 'IGNORE'> at load time to automatically
reap forked event children, preventing zombie processes. If you need to
manage child processes manually (e.g. to call C<waitpid> yourself), install
your own C<$SIG{CHLD}> handler after C<use Async::Event::Interval>.

=head1 METHODS - EVENT OPERATION

=head2 new($delay, $callback, @params)

Returns a new C<Async::Event::Interval> object. Does not start the event. Use
L<start()|/start(@params)> for that.

Parameters:

    $delay

Mandatory: The interval on which to trigger your event callback, in seconds.
Represent partial seconds as a floating point number. If zero is specified,
we'll simply run the event once and stop.

    $callback

Mandatory: A reference to a subroutine that will be called every time the
interval expires.

    @params

Optional, List: A list of parameters to pass to the callback. Note that these
are not shared parameters and are a copy only, so changes to them in the main
code will not be seen in the event, and vice-versa. See L</shared_scalar> if
you'd like to use variables that can be shared between the main application and
the events.

These parameters are sent into the event only once. Each time the callback is
called, they will receive the exact same set of params.

To have the event get different values in the params each time the callback is
called, see L<start()|/start(@params)>.

B<Note>: You can set a per-callback-execution timeout via
L<timeout()|/timeout($seconds)> before calling C<start()> to have the event
terminate itself if a callback runs longer than the specified number of seconds.

B<Note>: You can set L<immediate()|/immediate($value)> to have the callback fire
immediately on C<start()>, rather than waiting for the first interval.

=head2 start(@params)

Starts the event timer. Each time the interval is reached, the event callback
is executed.

Parameters:

    @params

Optional, List: A list of parameters that the callback will receive each time
the callback is called. This is most effective in single-run mode so you can
send in different parameter values on each incarnation. The parameters can be
any type of any complexity. Your callback will get them in whatever order you
send them in as.

=head2 stop

Stops the event from being executed.

Sets a cooperative C<_stop_requested> flag in shared memory so a well-behaved
child exits its event loop on the next iteration. If the child is stuck in a
long-running callback, escalates: sends C<SIGTERM> and polls for up to
C<STOP_TERM_TIMEOUT> seconds, then sends C<SIGKILL> and polls for up to
C<STOP_KILL_TIMEOUT> seconds. Croaks if the process survives both signals.

=head2 restart

Alias for C<start()>. Re-starts a C<stop()>ped event.

=head2 status

Returns the event's process ID (true) if it is running, C<0> (false) if it
isn't.

B<Side effect>: calling C<status()> probes the event's child process with
C<kill 0> to detect a crashed background process. If the process is gone,
the event's internal C<_started> flag is cleared, an internal C<_crashed>
flag is set, and C<pid> is cleared (so L</pid> subsequently returns
C<undef>). Subsequent calls to C<status()>, L</error>, or L</waiting>
see the updated state. To clear the crash flag, call L<start()|/start(@params)>
or L</restart>.

=head2 wait($interval)

Blocks until L<waiting()|/waiting> returns true, polling at the given
interval. Useful for one-shot events where you want to wait for the callback
to finish without writing the poll loop by hand.

Parameters:

    $interval

Optional, Number: Polling interval in seconds (integer or float). Defaults to
C<0.01>.

Return: Nothing.

B<Note>: C<wait()> returns once the event is dormant for any reason, including
crash. inspect L</error> and/or L</error_message> if you need to distinguish a
clean finish from a crash.

=head2 waiting

Returns true if the event is dormant and is ready for a C<start()> or
C<restart()> command. Returns false if the event is already running.

B<Side effect>: calls C</error()> and C<status()> internally, both of which
probe the child process (see those methods for details).

The same state is also surfaced as the C<waiting> field in L</events> and
L</info> snapshots, where it can be read without the side effects of this
method.

=head2 error

Returns true if an event crashed unexpectedly in the background, and is ready
for a C<start()> or C<restart()> command. Returns false if the event is not in
an error state.

B<Side effect>: calling C<error()> runs the same crash probe documented
under L</status>. The event's internal flags and PID may be mutated as a
side effect of this call.

The same state is also surfaced as the C<error> field in L</events> and
L</info> snapshots, where it can be read without the side effects of this
method (and without per-object access).

B<Note>: See L</errors> for the crash count, and L</error_message> for the
actual error message.

=head2 interval($seconds)

Gets/sets the delay time (in seconds) between each execution of the event's
callback code. You can use this method to change the delay between event
execution during the event's lifecycle.

Parameters:

    $seconds

Optional, Number: The number of seconds (integer or floating point) to delay
between executions.

Return: Number (integer or float), the number of seconds between execution
runs. If the interval was set to zero, the return will be C<0>.

=head2 timeout($seconds)

Sets (or gets) a per-callback-execution timeout in seconds. If the event's
callback takes longer than the specified time to complete, the event will
terminate itself with an error.

Parameters:

    $seconds

Optional, Integer: The number of whole seconds the callback is allowed to
execute for before timing out. Must be a non-negative integer; fractional
seconds are not supported. Use C<0> or C<undef> to disable.

Default: C<0>

Return: Currently set value.

B<Note>: The timeout is read from shared memory at the start of every callback
invocation, so changes made via this setter while an event is running take
effect on the next iteration of the interval loop (mirroring
L<interval()|/interval($seconds)>).

=head2 immediate($value)

Sets (or gets) whether the callback fires immediately on
L<start()|/start(@params)>, bypassing the first interval wait. Subsequent
invocations follow the normal interval cadence.

Parameters:

    $value

Optional, Integer: C<1> to enable immediate first execution, C<0> or C<undef>
to disable. Must be a non-negative integer when defined.

Default: C<0>

Return: Currently set value.

B<Note>: The flag is read from shared memory on each iteration of the event
loop. Changes made before calling the initial L<start()|/start(@params)> always
take effect. Changes made after C<start()> take effect on the next loop
iteration; however, once the first callback has executed, C<immediate> has
already served its purpose and further changes will not trigger another
immediate execution. Restart the event for a fresh C<immediate> check.

B<Note>: This feature is a no-op when running in single run mode. In that mode,
the event is always fired immediately on a call to C<start()>.

=head2 shared_scalar

Returns a reference to a scalar variable that can be shared between the main
process and the events. This reference can be used within multiple events, and
multiple shared scalars can be created by each event.

To read from or assign to the returned scalar, dereference it:

    $$s = 42;              # plain number
    $$s = 'some string';   # plain string
    $$s = { key => 'v' };  # hashref
    $$s = [1, 2, 3];       # arrayref

B<Supported values>: Internally L<IPC::Shareable> serializes to JSON by
default, so values must be JSON-representable: scalars (strings/numbers),
arrayrefs, hashrefs, and combinations of those. Blessed objects, code
references, regex references, and globs are B<not> supported and will be
silently lost or corrupt the segment.

Nested references work transparently and cleanup is automatic. Note that
under the hood, each nested hashref/arrayref allocates its own child
shared-memory segment, so very deeply nested structures consume one shm
segment per node:

    $$s = { config => { db => { host => 'localhost', port => 5432 } } };

    my $host = $$s->{config}{db}{host};   # 'localhost'

B<Updating a stored hashref>: When extending a hashref already in the scalar,
mutate through the dereference directly. Do not fetch the reference into a
lexical, mutate it, and store it back: that pattern corrupts the segment
because the fetched reference still carries C<IPC::Shareable>'s tied magic,
and re-storing a tied value into its own parent breaks the serialization:

    # Recommended: direct dereferenced mutation
    $$s->{new_key} = 'val';

    # Also works (modern stacks): spread + reassign
    $$s = { %{$$s}, new_key => 'val' };

    # Unreliable: re-storing a fetched reference corrupts the segment
    # my $h = $$s; $h->{new_key} = 'val'; $$s = $h;

The spread idiom replaces the entire stored value, which on older
C<IPC::Shareable> versions can lose accumulated cross-process writes
(later writers replacing earlier writers' data). The direct dereferenced
mutation avoids the nested-segment STORE path and is the more portable
choice.

B<Lifetime>: The underlying shared memory segment is owned by the event object
that created it. When the event goes out of scope (and its C<DESTROY> runs),
every C<shared_scalar> it created is released. Do not dereference the returned
scalar reference after the owning event has been destroyed; the segment will no
longer exist. If you need a shared scalar whose lifetime is independent of any
event, tie it directly with L<IPC::Shareable>.

B<Hex keys>: L</info> and L</events> return C<shared_scalars> as an arrayref of
hex key strings. These identify the underlying IPC segments and can be used to
re-attach from another process:

    my $info = $event->info;

    for my $key (@{ $info->{shared_scalars} }) {
        tie my $scalar, 'IPC::Shareable', $key, {};
        print "$$scalar\n";
    }

In practice, however, it is simpler to retain the reference returned by
C<shared_scalar()> and use it directly.

=head1 METHODS - EVENT INFORMATION

=head2 errors

Returns the number of times a started or restarted event has crashed
unexpectedly. See L</error> to test whether the event is currently in an
error state.

=head2 error_message

Returns the error message (if any) that caused the most recent event crash.

If the crash was caused by L<timeout()|/timeout($seconds)> firing, the message
has the form C<"Callback timed out after N seconds"> (where C<N> is the timeout
in whole seconds), which consumers can pattern-match on to distinguish timeouts
from other callback failures.

=head2 events

Returns a plain hash reference containing a snapshot of the data for all
existing events. The returned hash is a B<copy>; modifying it will not affect
the live events. C<shared_scalars> is an arrayref of the hex key strings for
each shared scalar created by the event; use the scalar reference returned by
L</shared_scalar> to read or write values.

The snapshot is taken under a read lock (C<LOCK_SH>) for consistency.

This method can be called as a class method
(C<Async::Event::Interval-E<gt>events>) since it returns data for all
events regardless of caller context.

    $VAR1 = {
        '0' => {
            'pid'       => 11859,
            'runs'      => 16,
            'errors'    => 0,
            'error'     => 0,
            'waiting'   => 0,
            'interval'  => 5,
            'shared_scalars' => [
                '0x4a3f2c1b5d6e',
                '0x7f8e9d0c1b2a'
            ],
        },
        '1' => {
            'pid'           => 11860,
            'runs'          => 447,
            'errors'        => 2,
            'error'         => 1,
            'waiting'       => 1,
            'interval'      => 0.6,
            'error_message' => 'File notes.txt not found at scripts/write_file.pl line 227',
        }
    };

C<error> is C<1> if the event is currently stopped because its callback
died (mirrors L</error>), C<0> otherwise. C<waiting> is C<1> if the event
is dormant and ready for a L<start()|/start(@params)>/L</restart> call (mirrors L</waiting>),
C<0> if it is currently running. See L</info> for the full lifecycle state
table.

=head2 id

Returns the integer ID of the event.

=head2 info

Returns a hash reference containing a snapshot of the event's data. The returned
hash is a B<copy>; modifying it will not affect the live event.
C<shared_scalars> is an arrayref of hex key strings; use the scalar reference
returned by L</shared_scalar> to read or write values.

The snapshot is taken under a read lock (C<LOCK_SH>) for consistency.

    $VAR1 = {
        'pid'      => 6841,
        'runs'     => 4077,
        'errors'   => 0,
        'error'    => 0,
        'waiting'  => 0,
        'interval' => 1.4,
        'shared_scalars' => [
            '0x4a3f2c1b5d6e',
            '0x7f8e9d0c1b2a'
        ],
    };

The C<error> and C<waiting> fields mirror the L</error> and L</waiting>
methods but can be read from any process holding a reference to the
C<%events> hash without the side effects of those methods. C<error> is a
B<stored> flag (written by the child when its callback dies, or by
C<_detect_crash> on the next probe for externally-killed children).
C<waiting> is B<derived> on every snapshot from C<pid>, C<error>, and a
C<kill(0, $pid)> liveness probe, so it always reflects the current state.

The following table summarises the values across the event lifecycle:

    State                                              error   waiting
    -----------------------------------------------------------------
    Just instantiated, never started                     0        1
    Currently running                                    0        0
    Stopped cleanly via stop()                           0        1
    One-shot finished cleanly                            0        1
    Callback died (interval mode)                        1        1
    Callback died (one-shot)                             1        1
    timeout() fired (callback alarmed out)               1        1
    External `kill -9` of the child                      1        1
    Restarted after a crash                              0        0

=head2 pid

Returns the Process ID the event is running under:

=over 4

=item * C<undef> before C<start()> has ever been called

=item * C<undef> after a crashed event has been detected (via a call to
L</error>, L</status>, or L</waiting>) and until the next
C<start()> / C<restart()>

=item * The PID of the most recent child after a clean C<stop()> (a dead
process; provided for diagnostic purposes only)

=item * A positive integer (the PID of the currently running child) otherwise

=back

B<Note>: Use L</status> and L</error> to determine which state applies;
B<do not> interpret the PID integer value beyond "some past or current child
PID". Prior versions returned the magic value C<-99> after a crash; that
sentinel has been retired in favor of L</error>.

=head2 runs

Returns the number of executions of the event's callback routine.

=head1 SCENARIOS/EXAMPLES

=head2 Run once

Send in an interval of zero (C<0>) to have your event run a single time. Call
L<start()|/start(@params)> (or C<restart()>) repeatedly for numerous
individual/one-off runs.

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(0, sub {print "hey\n";});

    $event->start;

    # Do other work while the event runs...

    # waiting() probes the child process; returns true once the
    # one-shot has finished, allowing a clean restart

    $event->start if $event->waiting;

    # If the event wasn't done, we reach here without the restart

=head2 Run once and wait

Run once, but wait for the task to finish. You could optionally put the wait()
inside of a condition if desired.

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(0, sub {print "hey\n";});

    $event->start;

    $event->wait;

    if ($event->error) {
        my $error_message = sprintf(
            "Callback crashed: $s",
            $event->error_message
        );

        die $error_message;
    }

=head2 Change delay interval during operation

Change the delay interval from 5 to 600 seconds after the event has fired 100
times

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(5, sub {print "hey\n";});

    $event->start;

    while (1) {
        if ($event->runs > 99 && $event->interval != 600) {
            $event->interval(600);
        }

        #... do stuff
    }

=head2 Closures and lexical variables

When a callback closes over a lexical variable, the child process sees the value
that existed at the moment of C<fork>. For one-shot events (interval C<0>), each
C<start()> forks a fresh child, so changes to the lexical between calls are
visible:

    use Async::Event::Interval;

    my $msg = "first run";
    my $event = Async::Event::Interval->new(0, sub { print "$msg\n"; });

    $event->start;       # prints "first run"

    $event->wait(0.3);

    $msg = "second run";
    $event->start;       # prints "second run"

B<Note>: For interval events (interval > 0), the child is forked once on the
first C<start()> and loops. Parent-side changes to closed-over lexicals will
never be seen by the already-running child. Use L</shared_scalar> or
C<start(@params)> for data that must cross process boundaries mid-run.

=head2 Per callback execution parameters

When using an event in a one-off situation where you restart the same event
manually, you can send in parameters that differ for each execution.

Send in a list of any data type. The list will be sent as-is to the callback.

B<Note>: Parameters sent in to the C<start()> method will override ones sent
into the C<new()> method.

For example:

    use Async::Event::Interval;

    my @params = (
        { a => 1 },
        { b => 2 },
        { c => 3 },
    );

    my $event = Async::Event::Interval->new(0, \&callback);

    my $count = 0;

    for my $href (@params) {
        $event->start($count, $href);
        $event->wait;
        $count++;
    }

    sub callback {
        my ($count, $href) = @_;
        my ($k, $v) = each %$href;
        print "$count: $k = $v\n";
    }

=head2 Global event callback parameters

You can send in a list of parameters to the event callback when instantiating
the event. Note that these parameters will remain the same for every call of
the callback.

Changing these within the main program will have no effect on the values sent
into the event itself. These parameter variables are copies and are not shared.
For shared variables, see L</shared_scalar>.

    use Async::Event::Interval;

    my @params = qw(1 2 3);

    my $event = Async::Event::Interval->new(
        1,
        \&callback,
        @params
    );

    sub callback {
        my ($one, $two, $three) = @_;
        print "$one, $two, $three\n";
    }

=head2 Shared data across events

This software uses L<IPC::Shareable> internally, so it's automatically
installed for you already. You can use shared data for use across many processes
and events, and if you use the same IPC key, even across multiple scripts.

Here's an example that uses a hash that's stored in shared memory, where the
parent process (the script) and two other processes (the two events) all share
and update the same hash.

B<Important>: keep shared hash values flat (strings, numbers). Nested data
structures (e.g. C<< $hash{$$}{key} >>) cause L<IPC::Shareable> to create
child shared-memory segments whose ownership can conflict across forked
processes, leading to data loss. For per-event shared data, consider
L</shared_scalar> instead.

    use Async::Event::Interval;
    use IPC::Shareable;

    tie my %shared_data, 'IPC::Shareable', {
        key         => '123456789',
        create      => 1,
        destroy     => 1
    };

    $shared_data{$$}++;

    my $event_one = Async::Event::Interval->new(0.2, \&update);
    my $event_two = Async::Event::Interval->new(1, \&update);

    $event_one->start;
    $event_two->start;

    sleep 10;

    $event_one->stop;
    $event_two->stop;

    for my $pid (keys %shared_data) {
        printf(
            "Process ID %d executed %d times\n",
            $pid,
            $shared_data{$pid}
        );
    }

    for my $event ($event_one, $event_two) {
        printf(
            "Event ID %d with PID %d ran %d times, with %d errors and an interval" .
            " of %.2f seconds\n",
            $event->id,
            $event->pid,
            $event->runs,
            $event->errors,
            $event->interval
        );
    }

    sub update {
        # Because each event runs in its own process, $$ will be set to the
        # process ID of the calling event, even though they both call this
        # same function

        $shared_data{$$}++;
    }

=head2 Event error management

If an event crashes, print out error information and restart the event.

This example shows how to print the most recent error message and halt the
program so you can troubleshoot your callback if your event crashes five or more
times.

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(5, sub {print "hey\n";});

    $event->start;

    while (1) {

        #... do stuff

        if ($event->errors >= 5) {
            print $event->error_message;
            exit;
        }

        if ($event->error) {
            printf(
                "Runs: %d, Runs errored: %d, Last error message: %s\n",
                $event->runs,
                $event->errors,
                $event->error_message
            );

            $event->restart;
        }
    }

=head2 Event crash: Restart event

    use warnings;
    use strict;

    use Async::Event::Interval;

    # kill 9, $$ is a contrived self-kill to demonstrate crash detection

    my $event = Async::Event::Interval->new(0.5, sub { kill 9, $$; });

    $event->start;

    sleep 1; # Do stuff

    if ($event->error) {
        print "Event crashed, restarting\n";
        $event->restart;
    }

=head2 Event crash: End program

    use warnings;
    use strict;

    use Async::Event::Interval;

    # kill 9, $$ is a contrived self-kill to demonstrate crash detection

    my $event = Async::Event::Interval->new(0.5, sub { kill 9, $$; });

    $event->start;

    sleep 1; # Do stuff

    die "Event crashed, can't continue" if $event->error;

=head2 Immediate first execution

Set C<immediate> to have the callback fire right away on C<start()>, then repeat
at the regular interval thereafter:

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(5, sub { print "hey\n"; });
    $event->immediate(1);
    $event->start;

    # Callback executed immediately, doesn't wait for the first 5 second
    # interval

    sleep 10;
    $event->stop;

=head2 Event suicidal timeout

Built in is the ability to have the event C<die()> if your callback breaches a
timeout threshold. A timeout is set with L<timeout()|/timeout($seconds)>. It can
be set at any time; it will be picked up on each iteration of your callback.

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(60, sub { sleep 9; });
    $event->timeout(8);

    $event->start;

    while (1) {
        if ($event->error_message =~ /Callback timed out/) {
            print "Event callback timed out... exiting to troubleshoot\n";
            exit;
        }
    }

=head2 Shared scalar

L<shared_scalar()|/shared_scalar> returns a tied scalar reference whose value
lives in shared memory and is visible to the parent and to event callbacks.
The sub-sections below show common usage patterns; see
L<shared_scalar()|/shared_scalar> for the API reference and constraints.

=head3 Storing simple types

A shared scalar can hold any JSON-representable value: scalars, arrayrefs,
hashrefs, or combinations thereof.

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(0, sub {});

    my $s     = $event->shared_scalar;

    $$s = 42;
    $$s = 'hello';
    $$s = [1, 2, 3];
    $$s = { lang => 'Perl' };

    print "$$s->{lang}\n";

=head3 Event writes, parent reads

An event populates the scalar in the background; the parent reads it after
the callback finishes.

    use Async::Event::Interval;

    my $s;

    my $event = Async::Event::Interval->new(0, sub {
        $$s = { name => 'alice', score => 42 };
    });

    $s = $event->shared_scalar;

    $event->start;
    $event->wait;

    print "$$s->{name}: $$s->{score}\n";

=head3 Updating a stored hashref

When extending a hashref already in the scalar, mutate through the
dereference directly. The spread idiom also works on modern
C<IPC::Shareable> stacks but is less portable across forked writers on
older versions:

    $$s = { a => 1, b => 2 };

    # Recommended: direct dereferenced mutation
    $$s->{c} = 3;

    # Also works (modern stacks): spread + reassign
    $$s = { %{$$s}, d => 4 };

B<Do not> fetch the reference into a lexical, mutate it, and store it back
(C<< my $h = $$s; $h->{x} = 1; $$s = $h; >>) - that pattern corrupts the
segment. See L<shared_scalar()|/shared_scalar> for the full rules.

=head3 Two events sharing a scalar

Multiple events can read/write the same shared scalar via closure. The
segment is owned by the event that created it; other events reference it
through the closed-over variable.

    use Async::Event::Interval;

    my $s;

    my $event_a = Async::Event::Interval->new(0, sub {
        $$s = { source => 'A', value => 100 };
    });

    $s = $event_a->shared_scalar;

    my $event_b = Async::Event::Interval->new(0, sub {
        $$s->{source} = 'B';
    });

    $event_a->start;
    $event_a->wait;

    $event_b->start;
    $event_b->wait;

    print "source=$$s->{source} value=$$s->{value}\n";

=head3 Multiple scalars on one event

One event can own several shared scalars - for example, one for input the
callback reads and one for results the parent reads back.

    use Async::Event::Interval;

    my ($s_in, $s_out);

    my $event = Async::Event::Interval->new(0, sub {
        $$s_out = { sum => $$s_in->{a} + $$s_in->{b} };
    });

    $s_in  = $event->shared_scalar;
    $s_out = $event->shared_scalar;

    $$s_in = { a => 3, b => 4 };

    $event->start;
    $event->wait;

    print "Sum = $$s_out->{sum}\n";

=head3 Periodic background writes

An interval event writes to the shared scalar on each tick; the parent reads
the latest value at its own pace.

    use Async::Event::Interval;

    my $s;

    my $event = Async::Event::Interval->new(0.3, \&callback);
    $event->immediate(1);

    $s = $event->shared_scalar;

    $event->start;

    for (1..5) {
        sleep 1;
        print "$$s->{time} (tick $$s->{count})\n" if $$s;
    }

    $event->stop;

    sub callback {
        my $prev = ($$s && $$s->{count}) || 0;
        $$s = { time => scalar localtime, count => $prev + 1 };
    }


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
