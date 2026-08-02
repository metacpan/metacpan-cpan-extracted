use strict;
use warnings;

use Test2::V0;
use Test2::Tools::QuickDB;
use File::Path qw/remove_tree/;
use IO::Select;
use POSIX ();
use Time::HiRes qw/sleep time/;

# Owner-death recovery depends on the Unix watcher and POSIX signals.
skip_all "watcher owner-death handling is not supported on $^O"
    if $^O eq 'MSWin32';

my $db = get_db_or_skipall({driver => 'PostgreSQL'});
$db->stop if $db->started;    # clone() requires a stopped source

sub pid_alive {
    my ($pid) = @_;
    return $pid && kill(0, $pid) ? 1 : 0;
}

# Start a live disposable/reusable clone in a child owner, stop its server so
# graceful-vs-fast teardown is observable, then make the owner disappear via
# _exit().  The independent watcher inherits $err_w, allowing the supervising
# test process to collect its diagnostics through EOF.
sub owner_death_case {
    my (%params) = @_;

    pipe(my $meta_r, my $meta_w) or die "metadata pipe failed: $!";
    pipe(my $err_r,  my $err_w)  or die "stderr pipe failed: $!";

    my $owner_pid = fork();
    die "owner fork failed: $!" unless defined $owner_pid;

    if (!$owner_pid) {
        close($meta_r);
        close($err_r);

        close(STDERR);
        open(STDERR, '>&', $err_w) or POSIX::_exit(2);
        close($err_w);

        my $clone = eval {
            $db->clone(
                autostart    => 1,
                cleanup      => $params{cleanup},
                fast_destroy => 1,
            );
        };

        unless ($clone) {
            my $error = $@ || 'clone returned no database';
            $error =~ s/\s+/ /g;
            print {$meta_w} "ERROR\t$error\n";
            close($meta_w);
            POSIX::_exit(2);
        }

        my $watcher = $clone->watcher;
        print {$meta_w} join("\t",
            $watcher->server_pid,
            $watcher->watcher_pid,
            $clone->dir,
        ), "\n";
        close($meta_w);

        kill('STOP', $watcher->server_pid) or do {
            print STDERR "Could not stop server: $!\n";
            POSIX::_exit(3);
        };

        # Deliberately bypass Perl destructors and END blocks.  The watcher
        # must detect that this owner has disappeared and enforce its policy.
        POSIX::_exit(0);
    }

    close($meta_w);
    close($err_w);

    my $metadata = <$meta_r>;
    close($meta_r);

    waitpid($owner_pid, 0);
    my $owner_status = $?;

    unless (defined $metadata && $metadata !~ /^ERROR\t/) {
        my $error = defined($metadata) ? $metadata : 'owner produced no metadata';
        Test2::Tools::QuickDB::skipall_on_resource_error($error);
        return {error => $error, owner_status => $owner_status};
    }

    chomp($metadata);
    my ($server_pid, $watcher_pid, $dir) = split(/\t/, $metadata, 3);

    my $started = time;
    my $stderr = '';
    my $select = IO::Select->new($err_r);
    my $stderr_closed = 0;
    while (time - $started < $params{timeout}) {
        for my $ready ($select->can_read(0.1)) {
            my $bytes = sysread($ready, my $chunk, 8192);
            if (defined($bytes) && $bytes > 0) {
                $stderr .= $chunk;
            }
            elsif (defined($bytes)) {
                $stderr_closed = 1;
                last;
            }
        }
        last if $stderr_closed;
    }
    close($err_r);

    my $elapsed = time - $started;
    my $settle = time;
    while ((pid_alive($server_pid) || pid_alive($watcher_pid))
        && time - $settle < 5) {
        sleep 0.02;
    }

    # Failure-path containment: do not let a stopped database escape this
    # test.  These are exact pids announced by the just-exited owner.
    if (!$stderr_closed && pid_alive($server_pid)) {
        kill('CONT', $server_pid);
        kill('KILL', $server_pid);
    }
    if (!$stderr_closed && pid_alive($watcher_pid)) {
        my $reap_start = time;
        while (pid_alive($watcher_pid) && time - $reap_start < 5) {
            sleep 0.02;
        }
        kill('KILL', $watcher_pid) if pid_alive($watcher_pid);
    }

    return {
        dir           => $dir,
        elapsed       => $elapsed,
        owner_status  => $owner_status,
        server_pid    => $server_pid,
        stderr        => $stderr,
        stderr_closed => $stderr_closed,
        watcher_pid   => $watcher_pid,
    };
}

subtest disposable_fast_owner_death => sub {
    local $ENV{QDB_STOP_GRACE} = 8;

    my $case = owner_death_case(cleanup => 1, timeout => 15);
    if ($case->{error}) {
        fail('owner created the disposable clone');
        diag($case->{error});
        return;
    }

    is($case->{owner_status}, 0, 'owner exited via _exit without an error');
    ok($case->{stderr_closed}, 'watcher exited and closed stderr');
    ok($case->{elapsed} < 6,
        "owner-death teardown skipped the 8s graceful wait ($case->{elapsed}s)");
    is($case->{stderr}, '', 'fast owner-death teardown emitted no diagnostics');
    ok(!pid_alive($case->{server_pid}), 'server is gone');
    ok(!pid_alive($case->{watcher_pid}), 'watcher is gone');
    ok(!-d $case->{dir}, 'disposable data directory was removed');

    remove_tree($case->{dir}, {safe => 1})
        if !pid_alive($case->{server_pid})
        && !pid_alive($case->{watcher_pid})
        && -d $case->{dir};
};

subtest reusable_owner_death_stays_graceful => sub {
    local $ENV{QDB_STOP_GRACE} = 3;

    my $case = owner_death_case(cleanup => 0, timeout => 12);
    if ($case->{error}) {
        fail('owner created the reusable clone');
        diag($case->{error});
        return;
    }

    is($case->{owner_status}, 0, 'owner exited via _exit without an error');
    ok($case->{stderr_closed}, 'watcher exited and closed stderr');
    ok($case->{elapsed} >= 2.5,
        "reusable database retained graceful owner-death policy ($case->{elapsed}s)");
    like($case->{stderr}, qr/Server taking too long to shut down, sending SIGQUIT/,
        'captured the expected graceful-path fast-signal escalation');
    like($case->{stderr}, qr/Server still running, sending SIGKILL/,
        'captured the expected final escalation for the stopped server');
    ok(!pid_alive($case->{server_pid}), 'server is gone');
    ok(!pid_alive($case->{watcher_pid}), 'watcher is gone');
    ok(-d $case->{dir}, 'reusable data directory was preserved');

    remove_tree($case->{dir}, {safe => 1})
        if !pid_alive($case->{server_pid})
        && !pid_alive($case->{watcher_pid})
        && -d $case->{dir};
};

done_testing;
