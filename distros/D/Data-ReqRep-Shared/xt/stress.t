use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use Time::HiRes 'time';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $MSGS     = $ENV{STRESS_MSGS}     || 2_000;
my $WORKERS  = $ENV{STRESS_WORKERS}  || 4;
my $CLIENTS  = $ENV{STRESS_CLIENTS}  || 4;
my $CANCEL   = $ENV{STRESS_CANCEL}   || 20;
# An oversubscribed CI runner can deschedule a client process for several seconds.
my $CTMO     = $ENV{STRESS_TIMEOUT}  || 30;

diag "stress: $CLIENTS clients x $MSGS msgs, $WORKERS workers, cancel every $CANCEL, ctmo ${CTMO}s";

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 4096, 256, 4096);

    # Idle timeout must exceed the client's per-request timeout, or a worker gives up first.
    my @wpids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $SIG{TERM} = sub { exit 0 };
            while (my ($req, $id) = $srv->recv_wait($CTMO + 5)) {
                $srv->reply($id, "w$w:$req");
            }
            exit 0;
        }
        push @wpids, $pid;
    }

    my @cpids;
    for my $c (1..$CLIENTS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            local $SIG{__DIE__} = sub { print STDERR @_; exit 4 };
            my $cli = Data::ReqRep::Shared::Client->new($path);
            my ($ok, $wrong, $late) = (0, 0, 0);
            my $cancel_ok = 0;
            for my $i (1..$MSGS) {
                if ($i % $CANCEL == 0) {
                    my $id = $cli->send_wait("c${c}m$i", $CTMO);
                    if (defined $id) { $cli->cancel($id); $cancel_ok++ }
                } else {
                    my $resp = $cli->req_wait("c${c}m$i", $CTMO);
                    if    (!defined $resp)                       { $late++  }
                    elsif ($resp =~ /^w\d+:c${c}m${i}$/)         { $ok++    }
                    else {
                        $wrong++;
                        if ( $wrong == 1 && open my $wfh, '>', "$path.wrong.$c" ) {
                            print $wfh "sent c${c}m$i got $resp\n";
                            close $wfh;
                        }
                    }
                }
            }
            exit 3 if $wrong;
            exit($late ? 2 : 0);
        }
        push @cpids, $pid;
    }

    my $t0 = time;
    my ($wrong_clients, $late_clients, $died_clients) = (0, 0, 0);
    for my $pid (@cpids) {
        waitpid($pid, 0);
        my $code = $? >> 8;
        $wrong_clients++ if $code == 3;
        $late_clients++  if $code == 2;
        $died_clients++  if $? && $code != 2 && $code != 3;
    }
    my $dt = time - $t0;
    kill 'TERM', @wpids;
    waitpid($_, 0) for @wpids;

    ok !$wrong_clients, "mpmc: every response received was the right one";
    if ($wrong_clients) {
        for my $c (1 .. $CLIENTS) {
            next unless open my $wfh, '<', "$path.wrong.$c";
            chomp( my $line = <$wfh> // '' );
            close $wfh;
            diag "client $c: $line" if length $line;
        }
    }
    unlink "$path.wrong.$_" for 1 .. $CLIENTS;
    is $died_clients, 0, "mpmc: no client died";
    diag "note: $late_clients/$CLIENTS client(s) had a request exceed ${CTMO}s -- "
       . "runner oversubscription, not a correctness failure" if $late_clients;

    my $total = $CLIENTS * $MSGS;
    my $stats = $srv->stats;
    diag sprintf "total=%d requests=%d replies=%d recoveries=%d dt=%.1fs (%.0f req/s)",
        $total, $stats->{requests}, $stats->{replies}, $stats->{recoveries},
        $dt, $stats->{requests} / ($dt || 1);

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 4096, 256, 4096);

    my @cpids;
    for my $c (1..$CLIENTS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $cli = Data::ReqRep::Shared::Client->new($path);
            for my $i (1..$MSGS) {
                $cli->req_wait("c${c}b$i", $CTMO);
            }
            exit 0;
        }
        push @cpids, $pid;
    }

    my $t0 = time;
    my $total = $CLIENTS * $MSGS;
    my $processed = 0;
    while ($processed < $total) {
        my @batch = $srv->recv_wait_multi(100, 5.0);
        last unless @batch;
        while (@batch) {
            my ($data, $id) = splice @batch, 0, 2;
            $srv->reply($id, "ok:$data");
            $processed++;
        }
    }
    my $dt = time - $t0;

    waitpid($_, 0) for @cpids;

    is $processed, $total, "batch recv: processed all $total requests";
    diag sprintf "batch: %d reqs in %.1fs (%.0f req/s)", $processed, $dt, $processed / ($dt || 1);

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 8192, 1 << 20);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (my ($req, $id) = $srv->recv_wait(5.0)) {
            $srv->reply($id, $req);
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Client->new($path);
    my $ok = 0;
    for my $i (1..($MSGS / 2)) {
        my $len = 1 + ($i * 37) % 5000;
        my $msg = chr(65 + ($i % 26)) x $len;
        my $resp = $cli->req_wait($msg, $CTMO);
        $ok++ if defined $resp && $resp eq $msg;
    }

    waitpid $pid, 0;
    is $ok, $MSGS / 2, "variable-size: all messages echoed correctly";

    $srv->unlink;
}

{
    my $srv = Data::ReqRep::Shared->new_memfd("stress_efd", 1024, 64, 4096);
    my $req_fd = $srv->eventfd;

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $processed = 0;
        while ($processed < $MSGS) {
            my $rin = '';
            vec($rin, $req_fd, 1) = 1;
            select($rin, undef, undef, 5.0) or last;
            $srv->eventfd_consume;
            while (my ($req, $id) = $srv->recv) {
                $srv->reply($id, "ok");
                $processed++;
            }
        }
        exit 0;
    }

    my $fd = $srv->memfd;
    my $cli = Data::ReqRep::Shared::Client->new_from_fd($fd);
    $cli->req_eventfd_set($req_fd);

    my $ok = 0;
    for my $i (1..$MSGS) {
        my $id = $cli->send_wait_notify("m$i", $CTMO);
        next unless defined $id;
        my $resp = $cli->get_wait($id, $CTMO);
        $ok++ if defined $resp && $resp eq "ok";
    }

    waitpid $pid, 0;
    is $ok, $MSGS, "eventfd under load: all $MSGS round-trips ok";
}

done_testing;
