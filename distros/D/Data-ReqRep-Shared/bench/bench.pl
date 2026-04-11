#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';

my $N = $ARGV[0] || 100_000;
my $msg = "hello world!";

sub fmt_rate {
    my $r = shift;
    return sprintf("%.1fM", $r / 1e6) if $r >= 1e6;
    return sprintf("%.1fK", $r / 1e3) if $r >= 1e3;
    return sprintf("%.0f", $r);
}

# --- Single-process echo ---
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # warmup
    for (1..1000) {
        my $id = $cli->send($msg);
        my ($r, $ri) = $srv->recv;
        $srv->reply($ri, $r);
        $cli->get($id);
    }

    my $t0 = time();
    for (1..$N) {
        my $id = $cli->send($msg);
        my ($r, $ri) = $srv->recv;
        $srv->reply($ri, $r);
        $cli->get($id);
    }
    my $el = time() - $t0;
    printf "Single-process echo:     %s req/s (%d iterations, %.1f ms)\n",
        fmt_rate($N / $el), $N, $el * 1000;
    $srv->unlink;
}

# --- Cross-process echo ---
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..($N + 1000)) {
            my ($r, $ri) = $srv->recv_wait(10.0);
            last unless defined $r;
            $srv->reply($ri, $r);
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Client->new($path);
    for (1..1000) { $cli->req($msg) }  # warmup

    my $t0 = time();
    for (1..$N) { $cli->req($msg) }
    my $el = time() - $t0;
    printf "Cross-process echo:      %s req/s (%d iterations, %.1f ms)\n",
        fmt_rate($N / $el), $N, $el * 1000;
    waitpid $pid, 0;
    $srv->unlink;
}

# --- Batch recv echo ---
{
    my $batch = 100;
    my $iters = int($N / $batch);
    my $total = $iters * $batch;
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 128, 4096);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # warmup
    for (1..10) {
        my @ids;
        push @ids, $cli->send($msg) for 1..$batch;
        my @items = $srv->recv_multi($batch);
        while (@items) {
            my (undef, $id) = splice @items, 0, 2;
            $srv->reply($id, $msg);
        }
        $cli->get($_) for @ids;
    }

    my $t0 = time();
    for (1..$iters) {
        my @ids;
        push @ids, $cli->send($msg) for 1..$batch;
        my @items = $srv->recv_multi($batch);
        while (@items) {
            my (undef, $id) = splice @items, 0, 2;
            $srv->reply($id, $msg);
        }
        $cli->get($_) for @ids;
    }
    my $el = time() - $t0;
    printf "Batch echo (%d/batch):   %s req/s (%d iterations, %.1f ms)\n",
        $batch, fmt_rate($total / $el), $total, $el * 1000;
    $srv->unlink;
}

# --- req_wait with timeout ---
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..($N + 1000)) {
            my ($r, $ri) = $srv->recv_wait(10.0);
            last unless defined $r;
            $srv->reply($ri, $r);
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Client->new($path);
    for (1..1000) { $cli->req_wait($msg, 5.0) }  # warmup

    my $t0 = time();
    for (1..$N) { $cli->req_wait($msg, 5.0) }
    my $el = time() - $t0;
    printf "Cross-process req_wait:  %s req/s (%d iterations, %.1f ms)\n",
        fmt_rate($N / $el), $N, $el * 1000;
    waitpid $pid, 0;
    $srv->unlink;
}
