package DBIx::QuickDB::Watcher;
use strict;
use warnings;

our $VERSION = '0.000049';

use Carp qw/croak/;
use POSIX qw/:sys_wait_h/;
use Time::HiRes qw/sleep time/;
use Scalar::Util qw/weaken/;
use File::Path qw/remove_tree/;

use DBIx::QuickDB::Util::HashBase qw{
    <db <args
    <server_pid
    <watcher_pid
    <master_pid
    <log_file

    <stopped
    <eliminated
    <detached

    <delete_data
};

sub init {
    my $self = shift;

    $self->{+MASTER_PID} ||= $$;

    $self->{+LOG_FILE} = $self->{+DB}->gen_log;

    $self->start();

    weaken($self->{+DB}) if $self->{+MASTER_PID} == $$;
}

sub start {
    my $self = shift;
    return if $self->{+SERVER_PID};

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not open pipe: $!";

    my $pid = fork;
    die "Could not fork: $!" unless defined $pid;

    if ($pid) {
        close($wh);
        waitpid($pid, 0);
        chomp($self->{+WATCHER_PID} = <$rh>);
        chomp($self->{+SERVER_PID}  = <$rh>);
        close($rh);
        die "Did not get watcher pid!" unless $self->{+WATCHER_PID};
        die "Did not get server pid!"  unless $self->{+SERVER_PID};
        return;
    }

    close($rh);
    POSIX::setsid();
    setpgrp(0, 0);
    $pid = fork;
    die "Could not fork: $!" unless defined $pid;
    POSIX::_exit(0) if $pid;

    $wh->autoflush(1);
    print $wh "$$\n";

    # In watcher now
    eval { $self->watch($wh); 1 } or POSIX::_exit(1);
    POSIX::_exit(0);
}

sub watch {
    my $self = shift;
    my ($wh) = @_;

    $0 = 'db-quick-watcher';

    my $kill = '';
    my $hup = 0;
    local $SIG{TERM} = sub { $kill = 'TERM' };
    local $SIG{INT}  = sub { $kill = 'INT' };
    local $SIG{USR1} = sub { $kill = 'FAST_TERM' };
    local $SIG{HUP} = sub { $hup = 1 };

    my $start_pid = $$;
    my $pid = $self->spawn();
    print $wh "$pid\n";
    close($wh);

    my $mpid = $self->{+MASTER_PID};
    my $spid = $self->{+SERVER_PID} or die "No server pid";

    my $ddir = $self->{+DB}->dir;
    my $ssig = $self->{+DB}->stop_sig // 'TERM';
    my $fsig = $self->{+DB}->fast_stop_sig // 'KILL';

    # Ignore SIGTERM/SIGINT before exec so the watcher cannot be killed
    # during startup before _do_watch installs its signal handlers.
    # SIG_IGN persists across exec, and any pending signal will be held
    # until _do_watch replaces these with proper handlers.
    $SIG{TERM} = 'IGNORE';
    $SIG{INT}  = 'IGNORE';

    # Block (rather than ignore) the fast-eliminate signal across the exec. A
    # blocked signal stays *pending* instead of being discarded, so a
    # fast_eliminate() that races server startup -- arriving after the socket is
    # up (so the caller's start() has returned) but before _do_watch has
    # installed its handler -- is not lost: _do_watch unblocks it once the
    # handler is in place and it fires immediately. SIG_IGN would silently drop
    # it, leaving the caller's wait() to block for the full stop-grace timeout.
    POSIX::sigprocmask(POSIX::SIG_BLOCK(), POSIX::SigSet->new(POSIX::SIGUSR1()));

    exec(
        $^X, '-Ilib',

        '-e' => "require DBIx::QuickDB::Watcher; DBIx::QuickDB::Watcher->_do_watch()",

        master_pid  => $mpid,
        data_dir    => $ddir,
        server_pid  => $spid,
        signal      => $ssig,
        fast_signal => $fsig,
        kill        => $kill,
        hup         => $hup,
    );
}

sub _do_watch {
    my $class = shift;

    $0 = 'db-quick-watcher';

    my %params = @ARGV;

    my $kill = $params{kill} // '';
    my $hup  = $params{hup}  // 0;
    local $SIG{TERM} = sub { $kill = 'TERM' };
    local $SIG{INT}  = sub { $kill = 'INT' };
    local $SIG{USR1} = sub { $kill = 'FAST_TERM' };
    local $SIG{HUP}  = sub { $hup  = 1 };

    # watch() blocked SIGUSR1 before exec so a fast_eliminate() racing startup
    # would stay pending rather than be discarded. Now that the handler above is
    # installed, unblock it -- any pending fast-eliminate fires here and sets
    # $kill before we enter the watch loop.
    POSIX::sigprocmask(POSIX::SIG_UNBLOCK(), POSIX::SigSet->new(POSIX::SIGUSR1()));

    my $blah;
    close(STDIN);
    open(STDIN, '<', \$blah) or warn "$!";

    my $master_pid  = $params{master_pid} or die "No master pid provided";
    my $server_pid  = $params{server_pid} or die "No server pid provided";
    my $data_dir    = $params{data_dir}   or die "No data dir provided";
    my $signal      = $params{signal} // 'TERM';
    my $fast_signal = $params{fast_signal} // 'KILL';

    my $hupped = 0;
    while (!$kill) {
        if ($hup && !$hupped) {
            close(STDOUT);
            open(STDOUT, '>', \$blah) or warn "$!";
            close(STDERR);
            open(STDERR, '>', \$blah) or warn "$!";
        }

        sleep 0.1;

        next if kill(0, $master_pid);
        $kill = 'TERM';
    }

    unless (eval { $class->_watcher_terminate(send_sig => $signal, fast_sig => $fast_signal, got_sig => $kill, pid => $server_pid, dir => $data_dir); 1 }) {
        my $err = $@;
        eval { warn $@ };
        POSIX::_exit(1);
    }

    POSIX::_exit(0);
}

sub spawn {
    my $self = shift;

    croak "Extra spawn" if $self->{+SERVER_PID};

    my $db   = $self->{+DB};
    my $args = $self->{+ARGS} || [];

    my $init_pid = $$;
    my ($pid, $log_file) = $db->run_command([$db->start_command, @$args], {no_wait => 1, log_file => $self->{+LOG_FILE}});
    $self->{+SERVER_PID} = $pid;
    $self->{+LOG_FILE}   = $log_file;

    return $pid;
}

sub _watcher_terminate {
    my $class = shift;
    my %params = @_;

    my $pid = $params{pid} or die "No pid";
    my $dir = $params{dir} or die "No dir";

    my $got_sig  = $params{got_sig};
    my $send_sig = $params{send_sig} // $got_sig // 'TERM';

    # fast_eliminate(): kill the server immediately with its fast-stop signal
    # (SIGKILL by default, or a clean immediate-shutdown signal the driver picks
    # to avoid leaking OS resources), reap it, drop the data dir. No graceful
    # shutdown -- the data dir is disposable so its integrity does not matter.
    # Used only for clones being deleted.
    if ($got_sig && $got_sig eq 'FAST_TERM') {
        $class->_watcher_kill_fast($pid, $params{fast_sig});

        # Ignore errors here.
        my $err = [];
        remove_tree($dir, {safe => 1, error => \$err}) if -d $dir;

        return;
    }

    $class->_watcher_kill($send_sig, $pid, $params{fast_sig});

    if ($got_sig && $got_sig eq 'TERM') {
        # Ignore errors here.
        my $err = [];
        remove_tree($dir, {safe => 1, error => \$err}) if -d $dir;
    }
}

sub _watcher_kill_fast {
    my $class = shift;
    my ($pid, $sig) = @_;

    $sig ||= 'KILL';

    kill($sig, $pid) or return;

    # Reap the server. With SIGKILL this resolves almost immediately. With a
    # clean immediate-shutdown signal (e.g. PostgreSQL's SIGQUIT, chosen so the
    # postmaster releases its SysV semaphores instead of leaking them) the
    # server needs a moment to abort its backends and exit; give it a short
    # window, then escalate to SIGKILL so teardown always completes even if that
    # signal is caught and ignored. The outer cap guards pathological cases
    # (e.g. a process stuck in uninterruptible IO).
    my $escalated = $sig eq 'KILL';
    my ($check, $exit);
    my $start = time;

    until ($check) {
        local $?;

        $check = waitpid($pid, WNOHANG);
        $exit = $?;
        last if $check;

        my $delta = time - $start;

        if (!$escalated && $delta > 2) {
            kill('KILL', $pid);
            $escalated = 1;
        }

        last if $delta > 5;

        sleep 0.01;
    }

    die "PID refused to exit after fast kill" unless $check;
    die "Something else reaped our process" if $check < 0;
    die "Reaped the wrong process '$check' instead of '$pid'" if $pid != $check;

    return;
}

sub _watcher_kill {
    my $class = shift;
    my ($sig, $pid, $fast_sig) = @_;

    $fast_sig ||= 'KILL';

    kill($sig, $pid) or die "Could not send kill signal";

    # How long to wait for a graceful shutdown before escalating, and how much
    # longer before giving up entirely. Keep this generous: a slow or loaded
    # host (e.g. a CPAN smoke box) can need well over a few seconds to finish
    # PostgreSQL's shutdown checkpoint. A premature hard kill leaves the data dir
    # in a crash-recovery state, and a clone of that dir then replays WAL on
    # first start, jumping SERIAL sequences forward by SEQ_LOG_VALS (32) --
    # silently corrupting cloned databases. Tunable via QDB_STOP_GRACE.
    my $kill_after = $ENV{QDB_STOP_GRACE};
    $kill_after = 4 unless defined($kill_after) && $kill_after =~ /^\d+$/ && $kill_after > 0;

    # Two-stage escalation once the graceful signal has not stopped the server by
    # $kill_after. First send the driver's fast-stop signal -- an immediate but
    # *clean* shutdown (e.g. PostgreSQL SIGQUIT) that still lets the server run
    # its exit cleanup and RELEASE OS resources such as SysV semaphores. Only if
    # that is also ignored do we SIGKILL. Going straight to SIGKILL here would
    # orphan those semaphores permanently -- the data dir is about to be deleted
    # so no future server reuses the IPC key -- and a suite that kills many
    # servers this way exhausts the host's SEMMNI/SEMMNS limits. When the driver
    # leaves fast_stop_sig at its 'KILL' default both stages are SIGKILL, which
    # is harmless. A final reap window after the SIGKILL lets it take effect
    # before we give up; the whole budget stays under Driver::stop's wait()
    # timeout (2*grace+2) so the watcher is not killed mid-reap.
    my $step    = $kill_after > 1 ? int($kill_after / 2) : 1;
    my $fast_at = $kill_after;
    my $kill_at = $fast_at + $step;
    my $give_up = $kill_at + $step;

    my ($check, $exit, $sent_fast, $sent_kill);
    my $start = time;
    until ($check) {
        local $?;
        my $delta = time - $start;

        if ($delta >= $fast_at && !$sent_fast) {
            warn "Server taking too long to shut down, sending SIG$fast_sig";
            kill($fast_sig, $pid);
            $sent_fast = 1;
        }

        if ($delta >= $kill_at && !$sent_kill) {
            warn "Server still running, sending SIGKILL" unless $fast_sig eq 'KILL';
            kill('KILL', $pid);
            $sent_kill = 1;
        }

        $check = waitpid($pid, WNOHANG);
        $exit = $?;

        last if $check;
        last if $delta > $give_up;

        sleep 0.1;
    }

    die "PID refused to exit" unless $check;
    die "Something else reaped our process" if $check < 0;
    die "Reaped the wrong process '$check' instead of '$pid'" if $pid != $check;

    return;
}

# stop(), eliminate(), and detach() each signal the watcher process by pid. Once
# ANY terminal teardown has been initiated, the watcher is exiting (or already
# gone) and the OS may recycle its pid to an unrelated process -- notably a
# sibling database's postmaster. A second signal would then land on the wrong
# process and shut down a live server out from under its owner. So once a stop
# or eliminate has been sent, never signal this pid again. (Data-dir cleanup for
# a stopped database is handled by Driver::DESTROY, not by a second signal.)
sub stop {
    my $self = shift;
    return if $self->{+STOPPED}++ || $self->{+ELIMINATED};
    my $pid = $self->{+WATCHER_PID} or return;
    kill('INT', $pid);
}

sub eliminate {
    my $self = shift;
    return if $self->{+ELIMINATED}++ || $self->{+STOPPED};
    my $pid = $self->{+WATCHER_PID} or return;
    kill('TERM', $pid);
}

# Like eliminate(), but the watcher kills the server immediately with the
# driver's fast_stop_sig (SIGKILL by default, or a clean immediate-shutdown
# signal) rather than attempting a graceful shutdown. Sets ELIMINATED so the
# normal teardown signals are never also sent to this (possibly
# soon-to-be-recycled) pid.
sub fast_eliminate {
    my $self = shift;
    return if $self->{+ELIMINATED}++ || $self->{+STOPPED};
    my $pid = $self->{+WATCHER_PID} or return;
    kill('USR1', $pid);
}

sub detach {
    my $self = shift;
    return if $self->{+DETACHED}++;
    return if $self->{+STOPPED} || $self->{+ELIMINATED};
    my $pid = $self->{+WATCHER_PID} or return;
    kill('HUP', $pid);
}

sub wait {
    my $self = shift;
    my $pid = $self->{+WATCHER_PID} or return;

    # Give the watcher long enough to finish a graceful shutdown before we
    # SIGKILL it. The watcher escalates to SIGKILL on the server after
    # QDB_STOP_GRACE and gives up at twice that, so this must outlast the
    # watcher's give-up or we would kill it mid-shutdown and orphan a
    # half-stopped server. Defaults to 10s (grace 4 -> give-up 8 -> 10).
    my $grace = $ENV{QDB_STOP_GRACE};
    $grace = 4 unless defined($grace) && $grace =~ /^\d+$/ && $grace > 0;
    my $timeout = $grace * 2 + 2;

    my $start = time;
    while(kill(0, $pid)) {
        my $waited = time - $start;
        if ($waited > $timeout) {
            kill('KILL', $pid);
            $start = time;
        }
        sleep 0.02;
    }

    # The watcher has exited; forget its pid so no later teardown signal (e.g.
    # from DESTROY) can land on a recycled pid now owned by another process.
    delete $self->{+WATCHER_PID};
}

sub DESTROY {
    my $self = shift;

    if ($self->{+MASTER_PID} == $$) {
        $self->eliminate;
        $self->wait;
    }
    else {
        unlink($self->{+LOG_FILE}) if $self->{+LOG_FILE};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Watcher - Daemon that sits between main process and the server.

=head1 DESCRIPTION

When a database is spun up a 'db-quick-watcher' process is started. This
process has 1 job: Make sure cleanup happens. This process is a daemon
completely disconnected from the process that requested the database, and the
db-server is a process under it.

If this process detects that your main process goes away (exited, killed, etc)
this process will kill the database server and delete the data dir, then exit.

The main process can also send signals to this one to make it stop, clean up,
etc.

=head1 SIGNALS

=over 4

=item SIGINT - Stop the server, but do not delete the data

This will stop the server, but keep the data dir intact.

=item SIGTERM - Stop the server, delete the data

This will stop the server, and if the instance is supposed to be cleaned up
then the data dir will be deleted.

=item SIGUSR1 - Fast eliminate: kill the server immediately, delete the data

Like SIGTERM, but the server is killed straight away with the driver's
C<fast_stop_sig()> (C<SIGKILL> by default, or a clean immediate-shutdown signal
the driver picks to avoid leaking OS resources) instead of being given a chance
to shut down gracefully, then reaped -- escalating to C<SIGKILL> if it does not
exit promptly -- then the data dir is removed. Used for disposable clones being
deleted (see L<DBIx::QuickDB::Driver/destroy_quietly>). The watcher blocks this
signal across its startup C<exec> so a fast-eliminate that races server startup
stays pending rather than being lost.

=item SIGHUP - Do not report errors

This will tell the daemon not to report when the server exits badly. This is
mainly used for garbage collection purposes.

=back

=head1 SOURCE

The source code repository for DBIx-QuickDB can be found at
F<https://github.com/exodist/DBIx-QuickDB/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
