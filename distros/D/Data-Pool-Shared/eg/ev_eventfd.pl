#!/usr/bin/env perl
# EV event loop integration via eventfd
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use EV;
use Data::Pool::Shared;
$| = 1;

my $pool = Data::Pool::Shared::I64->new(undef, 8);
my $efd = $pool->eventfd;
printf "pool capacity=%d, eventfd=%d\n\n", $pool->capacity, $efd;

my ($io_w, $alloc_w, $free_w, $stop_w);

$io_w = EV::io $efd, EV::READ, sub {
    my $n = $pool->eventfd_consume // return;
    printf "[watch] %d events, used=%d/%d\n", $n, $pool->used, $pool->capacity;
};

my $count = 0;
$alloc_w = EV::timer 0.05, 0.15, sub {
    my $s = $pool->try_alloc;
    if (defined $s) {
        $count++;
        $pool->set($s, $count * 100);
        printf "[alloc] slot %d = %d\n", $s, $pool->get($s);
        $pool->notify;
    }
};

$free_w = EV::timer 0.3, 0.2, sub {
    my $slots = $pool->allocated_slots;
    if (@$slots) {
        printf "[free]  slot %d\n", $slots->[0];
        $pool->free($slots->[0]);
        $pool->notify;
    }
};

$stop_w = EV::timer 1.5, 0, sub {
    undef $io_w; undef $alloc_w; undef $free_w; undef $stop_w;
};
EV::run;
printf "\ndone, used=%d\n", $pool->used;
$pool->reset;
