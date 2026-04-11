#!/usr/bin/env perl
# Benchmark: Int (lock-free) vs Str (mutex+arena)
use strict;
use warnings;
use Time::HiRes qw(time);
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $N = $ARGV[0] || 200_000;

sub fmt_rate {
    my $r = shift;
    return sprintf("%.1fM", $r / 1e6) if $r >= 1e6;
    return sprintf("%.1fK", $r / 1e3) if $r >= 1e3;
    return sprintf("%.0f", $r);
}

print "ReqRep Int vs Str, $N iterations\n\n";

# --- Single-process Int ---
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 1024, 64);
    my $cli = Data::ReqRep::Shared::Int::Client->new($path);

    for (1..1000) {
        my $id = $cli->send(42);
        my ($v, $ri) = $srv->recv;
        $srv->reply($ri, $v);
        $cli->get($id);
    }

    my $t0 = time();
    for (1..$N) {
        my $id = $cli->send(42);
        my ($v, $ri) = $srv->recv;
        $srv->reply($ri, $v);
        $cli->get($id);
    }
    my $el = time() - $t0;
    printf "  %-30s %8s req/s\n", "Single-process Int", fmt_rate($N / $el);
    $srv->unlink;
}

# --- Single-process Str ---
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);
    my $cli = Data::ReqRep::Shared::Client->new($path);
    my $msg = "hello world!";

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
    printf "  %-30s %8s req/s\n", "Single-process Str (12B)", fmt_rate($N / $el);
    $srv->unlink;
}

# --- Cross-process Int ---
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 1024, 64);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..($N + 1000)) {
            my ($v, $ri) = $srv->recv_wait(10.0);
            last unless defined $v;
            $srv->reply($ri, $v);
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Int::Client->new($path);
    $cli->req(42) for 1..1000;  # warmup

    my $t0 = time();
    $cli->req(42) for 1..$N;
    my $el = time() - $t0;
    printf "  %-30s %8s req/s\n", "Cross-process Int", fmt_rate($N / $el);
    waitpid $pid, 0;
    $srv->unlink;
}

# --- Cross-process Str ---
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);
    my $msg = "hello world!";

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
    $cli->req($msg) for 1..1000;

    my $t0 = time();
    $cli->req($msg) for 1..$N;
    my $el = time() - $t0;
    printf "  %-30s %8s req/s\n", "Cross-process Str (12B)", fmt_rate($N / $el);
    waitpid $pid, 0;
    $srv->unlink;
}

print "\nDone.\n";
