package DBIx::QuickDB::Watcher;
use strict;
use warnings;

our $VERSION = '0.000028';

use POSIX();
use Carp qw/croak/;
use Time::HiRes qw/sleep time/;
use Scalar::Util qw/weaken/;

use DBIx::QuickDB::Util::HashBase qw{
    <db <args
    <server_pid
    <watcher_pid
    <master_pid
    <log_file
    <detached

    <stopped
    <eliminated
};

sub init {
    my $self = shift;

    $self->{+MASTER_PID} ||= $$;

    weaken($self->{+DB});

    $self->{+LOG_FILE} = $self->{+DB}->gen_log;

    $self->start();
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
    $self->watch($wh);
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

sub watch {
    my $self = shift;
    my ($wh) = @_;

    $0 = 'db-quick-watcher';

    local $SIG{TERM} = sub { $self->_do_eliminate(); POSIX::_exit(0) };
    local $SIG{INT}  = sub { $self->_do_stop();      POSIX::_exit(0) };
    local $SIG{HUP}  = sub { $self->{+DETACHED} = 1 };

    my $pid = $self->spawn();
    print $wh "$pid\n";
    close($wh);

    while (1) {
        sleep 1;
        next if kill(0, $self->{+MASTER_PID});

        $self->_do_eliminate();
        POSIX::_exit(0);
    }

    POSIX::_exit(0) if $self->{+DETACHED};
    die "Scope Leak";
}

sub _do_stop {
    my $self = shift;

    my $db = $self->{+DB};
    my $pid = $self->{+SERVER_PID} or return;

    if (kill($db->stop_sig, $pid)) {
        my $check = waitpid($pid, 0);
        my $exit = $?;
        return if $self->{+DETACHED};
        if ($exit || $check ne $pid) {
            my $sig = $exit & 127;
            $exit = ($exit >> 8);
            warn "Server had bad exit: Pid: $pid, Check: $check, Exit: $exit, Sig: $sig";
            if (my $log_file = $self->{+LOG_FILE}) {
                if(open(my $fh, '<', $log_file)) {
                    print STDERR <$fh>;
                }
                else {
                    warn "Could not open log file: $!";
                }
            }
        }
    }
    else {
        return if $self->{+DETACHED};
        warn "Could not signal server to exit";
    }
}

sub _do_eliminate {
    my $self = shift;
    my $db = $self->{+DB};
    $self->_do_stop;
    $db->cleanup if $db->should_cleanup;
}

sub spawn {
    my $self = shift;

    croak "Extra spawn" if $self->{+SERVER_PID};

    my $db   = $self->{+DB};
    my $args = $self->{+ARGS} || [];

    my ($pid, $log_file) = $db->run_command([$db->start_command, @$args], {no_wait => 1, log_file => $self->{+LOG_FILE}});
    $self->{+SERVER_PID} = $pid;
    $self->{+LOG_FILE}   = $log_file;

    return $pid;
}

sub DESTROY {
    my $self = shift;

    if ($self->{+MASTER_PID} == $$) {
        $self->detach();
        $self->eliminate();
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

DBIx::QuickDB::Watcher - Daemon that sits between main process and mysqld

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

=item SIGTERM - Stop the server, delete the data (if requested)

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
