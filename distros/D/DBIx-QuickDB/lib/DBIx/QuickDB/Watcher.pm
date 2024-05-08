package DBIx::QuickDB::Watcher;
use strict;
use warnings;

our $VERSION = '0.000032';

use Carp qw/croak/;
use POSIX qw/:sys_wait_h/;
use Time::HiRes qw/sleep time/;
use Scalar::Util qw/weaken/;

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

    my $blah;
    close(STDIN);
    open(STDIN, '<', \$blah) or warn "$!";

    my $kill = 0;
    local $SIG{TERM} = sub { $kill = 'TERM' };
    local $SIG{INT}  = sub { $kill = 'INT' };

    local $SIG{HUP} = sub {
        close(STDOUT);
        open(STDOUT, '>', \$blah) or warn "$!";
        close(STDERR);
        open(STDERR, '>', \$blah) or warn "$!";
    };

    my $start_pid = $$;
    my $pid = $self->spawn();
    print $wh "$pid\n";
    close($wh);

    while (!$kill) {
        sleep 0.1;

        next if kill(0, $self->{+MASTER_PID});
        $kill = 'TERM';
    }

    unless (eval { $self->_watcher_terminate($kill); 1 }) {
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
    my $self = shift;
    my ($sig) = @_;

    $self->_watcher_kill();

    $self->{+DB}->cleanup() if $sig && $sig eq 'TERM';
}

sub _watcher_kill {
    my $self = shift;

    my $db = $self->{+DB};

    my $pid = $self->{+SERVER_PID} or die "No server pid";
    kill($db->stop_sig, $pid) or die "Could not send kill signal";

    my ($check, $exit, $killed);
    my $start = time;
    until ($check) {
        local $?;
        my $delta = time - $start;

        if ($delta >= 4) {
            if ($killed) {
                my $delta2 = time - $killed;
                next unless $delta2 >= 1;
            }

            warn "Server taking too long to shut down, sending SIGKILL";
            $killed = time;
            kill('KILL', $pid);

            last if $delta > 8;
        }

        $check = waitpid($pid, WNOHANG);
        $exit = $?;

        sleep 0.1;
    }

    die "PID refused to exit" unless $check;
    die "Something else reaped our process" if $check < 0;
    die "Reaped the wrong process '$check' instead of '$pid'" if $pid != $check;

    return;
}

sub stop {
    my $self = shift;
    return if $self->{+STOPPED}++;
    my $pid = $self->{+WATCHER_PID} or return;
    kill('INT', $pid);
}

sub eliminate {
    my $self = shift;
    return if $self->{+ELIMINATED}++;
    my $pid = $self->{+WATCHER_PID} or return;
    kill('TERM', $pid);
}

sub detach {
    my $self = shift;
    return if $self->{+DETACHED}++;
    my $pid = $self->{+WATCHER_PID} or return;
    kill('HUP', $pid);
}

sub wait {
    my $self = shift;
    my $pid = $self->{+WATCHER_PID} or return;

    my $start = time;
    while(kill(0, $pid)) {
        my $waited = time - $start;
        if ($waited > 10) {
            kill('KILL', $pid);
            $start = time;
        }
        sleep 0.02;
    }
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
