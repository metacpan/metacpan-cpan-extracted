package App::Base::Daemon::Supervisor;
use 5.010;
use Moose::Role;
with 'App::Base::Daemon';

our $VERSION = '0.08';    ## VERSION

=head1 NAME

App::Base::Daemon::Supervisor - supervise daemon process

=head1 SYNOPSIS

    package App::Base::Daemon::Foo;
    use Moose;
    with 'App::Base::Daemon::Supervisor';

    sub documentation { return 'foo'; }
    sub options { ... }
    sub supervised_process {
        my $self = shift;
        # the main daemon process
        while(1) {
            # check if supervisor is alive, exit otherwise
            $self->ping_supervisor;
            # do something
            ...
        }
    }
    sub supervised_shutdown {
        # this is called during shutdown
    }

=head1 DESCRIPTION

App::Base::Daemon::Supervisor allows to run code under supervision, it also
provides support for zero downtime reloading. When you run Supervisor based
daemon, the first process becomes a supervisor, it forks a child process which
invokes I<supervised_process> method that should contain the main daemon code.
Supervisor and worker connected with a socketpair. If the worker exits for some
reason, the supervisor detects it and starts a new worker after a small delay.
Worker should periodically call I<ping_supervisor> method, so it would be able
to detect the case when supervisor has been killed and exit.

If module needs hot reloading feature, it should redefine I<can_do_hot_reload>
method to return true value. In this case supervisor process sets a handler for
I<SIGUSR2> signal. When I<SIGUSR2> signal is received, supervisor starts a new
copy of the script via fork/exec, so this new copy runs a new code. New
supervisor starts a worker process and waits a signal that this new worker is
ready to do its job. To send that signal worker should invoke
I<ready_to_take_over> method.  Then the new supervisor receives that signal, it
sends I<SIGQUIT> to the old supervisor and waits for it to exit. After the old
supervisor exited (normally new supervisor detects that because it can flock
the pid file), the new supervisor sends signal to the worker,
I<ready_to_take_over> method in worker returns, and worker can start doing its
job. If supervisor receives I<SIGUSR2> when it is already in the process of
reloading, it ignores this signal. If supervisor didn't get I<SIGQUIT> in 60
seconds after starting hot reloading process, it sends I<SIGKILL> to the new
supervisor and resumes normal work.

=cut

use namespace::autoclean;
use Socket qw();
use POSIX  qw(:errno_h);
use Time::HiRes;
use IO::Handle;

=head1 REQUIRED METHODS

Class consuming this role must implement the following methods:

=cut

=head2 supervised_process

The main daemon subroutine. Inside this subroutine you should periodically
check that supervisor is still alive using I<ping_supervisor> method. If
supervisor exited, daemon should also exit.

=cut

requires 'supervised_process';

=head2 supervised_shutdown

This subroutine is executed then daemon process is shutting down. Put cleanup
code inside.

=cut

requires 'supervised_shutdown';

=head1 ATTRIBUTES

=cut

=head2 is_supervisor

returns true inside supervisor process and false inside supervised daemon

=cut

has is_supervisor => (
    is      => 'rw',
    default => 1,
);

=head2 delay_before_respawn

how long supervisor should wait after child process exited before starting a
new child. Default value is 5.

=cut

has delay_before_respawn => (
    is      => 'rw',
    default => 5,
);

=head2 supervisor_pipe

File descriptor of the pipe to supervisor

=cut

has supervisor_pipe => (
    is     => 'rw',
    writer => '_supervisor_pipe',
);

has _child_pid => (is => 'rw');

=head1 METHODS

=cut

=head2 $self->ping_supervisor

Should only be called from supervised process. Checks if supervisor is alive
and initiates shutdown if it is not.

=cut

sub ping_supervisor {
    my $self = shift;
    my $pipe = $self->supervisor_pipe or $self->error("Supervisor pipe is not defined");
    say $pipe "ping";
    my $pong = <$pipe>;
    unless (defined $pong) {
        $self->error("Error reading from supervisor pipe: $!");
    }
    return;
}

=head2 $self->ready_to_take_over

Used to support hot reloading. If daemon support hot restart,
I<supervised_process> is called while the old daemon is still running.
I<supervised_process> should perform initialization, e.g. open listening
sockets, and then call this method. Method will cause termination of old daemon
and after return the new process may start serving clients.

=cut

sub ready_to_take_over {
    my $self = shift;
    my $pipe = $self->supervisor_pipe or die "Supervisor pipe is not defined";
    say $pipe "takeover";
    my $ok = <$pipe>;
    defined($ok) or $self->error("Failed to take over");
    return;
}

=head2 $self->daemon_run

See L<App::Base::Daemon>

=cut

sub daemon_run {
    my $self = shift;
    $self->_set_hot_reload_handler;

    while (1) {
        socketpair my $chld, my $par, Socket::AF_UNIX, Socket::SOCK_STREAM, Socket::PF_UNSPEC;
        my $pid = fork;
        $self->_child_pid($pid);
        if ($pid) {
            local $SIG{QUIT} = sub {
                kill TERM => $pid;
                waitpid $pid, 0;
                exit 0;
            };
            $chld->close;
            $par->autoflush(1);
            $self->_supervisor_pipe($par);
            while (local $_ = <$par>) {
                chomp;
                if ($_ eq 'ping') {
                    say $par 'pong';
                } elsif ($_ eq 'takeover') {
                    $self->_control_takeover;
                    say $par 'ok';
                } elsif ($_ eq 'shutdown') {
                    kill KILL => $pid;
                    close $par;
                } else {
                    warn("Received unknown command from the supervised process: $_") unless $self->getOption('no-warn');
                }
            }
            my $kid = waitpid $pid, 0;
            warn("Supervised process $kid exited with status $?") unless $self->getOption('no-warn');
        } elsif (not defined $pid) {
            warn("Couldn't fork: $!") unless $self->getOption('no-warn');
        } else {
            local $SIG{USR2};
            $par->close;
            $chld->autoflush(1);
            $self->_supervisor_pipe($chld);
            $self->is_supervisor(0);
            $self->supervised_process;
            exit 0;
        }
        Time::HiRes::usleep(1_000_000 * $self->delay_before_respawn);
    }

    # for critic
    return;
}

# this initializes SIGUSR2 handler to perform hot reload
sub _set_hot_reload_handler {
    my $self = shift;

    return unless $self->can_do_hot_reload;
    my $upgrading;

    ## no critic (RequireLocalizedPunctuationVars)
    $SIG{USR2} = sub {
        return unless $ENV{APP_BASE_DAEMON_PID} == $$;
        if ($upgrading) {
            warn("Received USR2, but hot reload is already in progress") unless $self->getOption('no-warn');
            return;
        }
        warn("Received USR2, initiating hot reload") unless $self->getOption('no-warn');
        my $pid;
        unless (defined($pid = fork)) {
            warn("Could not fork, cancelling reload") unless $self->getOption('no-warn');
        }
        unless ($pid) {
            exec($ENV{APP_BASE_SCRIPT_EXE}, @{$self->{orig_args}})
                or $self->error("Couldn't exec: $!");
        }
        $upgrading = time;
        if ($SIG{ALRM}) {
            warn("ALRM handler is already defined!") unless $self->getOption('no-warn');
        }
        $SIG{ALRM} = sub {
            warn("Hot reloading timed out, cancelling") unless $self->getOption('no-warn');
            kill KILL => $pid;
            undef $upgrading;
        };
        alarm 60;
    };
    {
        my $usr2 = POSIX::SigSet->new(POSIX::SIGUSR2());
        my $old  = POSIX::SigSet->new();
        POSIX::sigprocmask(POSIX::SIG_UNBLOCK(), $usr2, $old);
    }

    return;
}

my $pid;

# kill the old daemon and lock pid file
sub _control_takeover {
    my $self = shift;

    ## no critic (RequireLocalizedPunctuationVars)

    # if it is first generation, when pid file should be already locked in App::Base::Daemon
    if ($ENV{APP_BASE_DAEMON_GEN} > 1 and $ENV{APP_BASE_DAEMON_PID} != $$) {
        kill QUIT => $ENV{APP_BASE_DAEMON_PID};
        if ($self->getOption('no-pid-file')) {

            # we don't have pid file, so let's just poke it to death
            my $attempts = 14;
            while (kill(($attempts == 1 ? 'KILL' : 'ZERO') => $ENV{APP_BASE_DAEMON_PID})
                and $attempts--)
            {
                Time::HiRes::usleep(500_000);
            }
        } else {
            local $SIG{ALRM} = sub {
                warn("Couldn't lock the file. Sending KILL to previous generation process") unless $self->getOption('no-warn');
            };
            alarm 5;

            # We may fail because two reasons:
            # a) previous process didn't exit and still holds the lock
            # b) new process was started and locked pid
            $pid = eval { File::Flock::Tiny->lock($self->pid_file) };
            unless ($pid) {

                # So let's try killing old process, if after that locking still will fail
                # then probably it is the case b) and we should exit
                kill KILL => $ENV{APP_BASE_DAEMON_PID};
                $SIG{ALRM} = sub { $self->error("Still couldn't lock pid file, aborting") };
                alarm 5;
                $pid = File::Flock::Tiny->lock($self->pid_file);
            }
            alarm 0;
            $pid->write_pid;
        }
    }
    $ENV{APP_BASE_DAEMON_PID} = $$;
    return;
}

=head2 $self->handle_shutdown

See L<App::Base::Daemon>

=cut

sub handle_shutdown {
    my $self = shift;
    if ($self->is_supervisor) {
        kill TERM => $self->_child_pid if $self->_child_pid;
    } else {
        $self->supervised_shutdown;
    }

    return;
}

=head2 DEMOLISH

=cut

sub DEMOLISH {
    my $self = shift;
    shutdown $self->supervisor_pipe, 2 if $self->supervisor_pipe;
    return;
}

no Moose::Role;
1;

__END__

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010-2014 Binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
