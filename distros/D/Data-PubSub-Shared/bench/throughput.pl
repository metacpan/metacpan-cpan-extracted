#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use Data::PubSub::Shared;

my $N = shift || 1_000_000;

sub rate { sprintf "%.1fM/s", $_[0] / $_[1] / 1e6 }

print "Data::PubSub::Shared throughput benchmark ($N items)\n\n";

# --- Int: single-process publish + poll ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 65536);
    my $sub = $ps->subscribe;

    my $t0 = time;
    for my $i (1..$N) {
        $ps->publish($i);
        $sub->poll;
    }
    my $dt = time - $t0;
    printf "Int publish+poll (interleaved):   %s\n", rate($N, $dt);
}

# --- Int: publish burst then poll burst ---
{
    my $cap = $N < 65536 ? $N : 65536;
    my $ps = Data::PubSub::Shared::Int->new(undef, $cap);

    my $t0 = time;
    for my $i (1..$N) { $ps->publish($i) }
    my $dt_pub = time - $t0;

    my $sub = $ps->subscribe_all;
    my $t1 = time;
    my @v = $sub->drain;
    my $dt_poll = time - $t1;
    printf "Int publish burst:                %s\n", rate($N, $dt_pub);
    printf "Int drain burst:                  %s (%d items)\n", rate(scalar @v, $dt_poll), scalar @v;
}

# --- Int: batch publish_multi ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 65536);
    my @batch = (1..100);
    my $batches = int($N / 100);

    my $t0 = time;
    for (1..$batches) { $ps->publish_multi(@batch) }
    my $dt = time - $t0;
    printf "Int publish_multi (100/batch):    %s\n", rate($batches * 100, $dt);
}

# --- Int32: publish + poll ---
{
    my $ps = Data::PubSub::Shared::Int32->new(undef, 65536);
    my $sub = $ps->subscribe;

    my $t0 = time;
    for my $i (1..$N) {
        $ps->publish($i);
        $sub->poll;
    }
    my $dt = time - $t0;
    printf "Int32 publish+poll (interleaved): %s\n", rate($N, $dt);
}

# --- Int16: publish + poll ---
{
    my $ps = Data::PubSub::Shared::Int16->new(undef, 65536);
    my $sub = $ps->subscribe;

    my $t0 = time;
    for my $i (1..$N) {
        $ps->publish($i);
        $sub->poll;
    }
    my $dt = time - $t0;
    printf "Int16 publish+poll (interleaved): %s\n", rate($N, $dt);
}

# --- Str: single-process publish + poll ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 65536);
    my $sub = $ps->subscribe;
    my $msg = "hello world 1234567890 abcdefgh";  # ~30 bytes

    my $t0 = time;
    for my $i (1..$N) {
        $ps->publish($msg);
        $sub->poll;
    }
    my $dt = time - $t0;
    printf "Str publish+poll (~30B, interl):  %s\n", rate($N, $dt);
}

# --- Str: publish burst then drain ---
{
    my $cap = $N < 65536 ? $N : 65536;
    my $ps = Data::PubSub::Shared::Str->new(undef, $cap);
    my $msg = "x" x 50;

    my $t0 = time;
    for my $i (1..$N) { $ps->publish($msg) }
    my $dt_pub = time - $t0;

    my $sub = $ps->subscribe_all;
    my $t1 = time;
    my @v = $sub->drain;
    my $dt_poll = time - $t1;
    printf "Str publish burst (~50B):         %s\n", rate($N, $dt_pub);
    printf "Str drain burst:                  %s (%d items)\n", rate(scalar @v, $dt_poll), scalar @v;
}

# --- Str: batch publish_multi ---
{
    my $ps = Data::PubSub::Shared::Str->new(undef, 65536);
    my @batch = map { "msg-$_-payload" } 1..100;
    my $batches = int($N / 100);

    my $t0 = time;
    for (1..$batches) { $ps->publish_multi(@batch) }
    my $dt = time - $t0;
    printf "Str publish_multi (100/batch):   %s\n", rate($batches * 100, $dt);
}

# --- Int: poll_cb vs while(poll) ---
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 65536);
    $ps->publish($_) for 1..($N > 65536 ? 65536 : $N);
    my $items = $ps->write_pos;

    my $sub1 = $ps->subscribe_all;
    my $t0 = time;
    my $n1 = $sub1->poll_cb(sub {});
    my $dt1 = time - $t0;

    my $sub2 = $ps->subscribe_all;
    my $t1 = time;
    1 while defined $sub2->poll;
    my $dt2 = time - $t1;

    printf "Int poll_cb:                     %s\n", rate($n1, $dt1);
    printf "Int while(poll):                 %s\n", rate($items, $dt2);
}

print "\nDone.\n";
