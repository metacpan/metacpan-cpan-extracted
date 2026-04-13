#!/usr/bin/env perl
# EV event loop: child sets bits, parent reacts on eventfd
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use EV;
use POSIX qw(_exit);
use Data::BitSet::Shared;
$| = 1;

my $bs = Data::BitSet::Shared->new(undef, 64);
my $efd = $bs->eventfd;

my ($io_w, $stop_w);
$io_w = EV::io $efd, EV::READ, sub {
    $bs->eventfd_consume;
    printf "[watch] count=%d set_bits=[%s]\n", $bs->count, join(' ', $bs->set_bits);
};

my $pid = fork // die;
if ($pid == 0) {
    for my $b (0, 10, 20, 30, 42, 63) {
        $bs->set($b);
        $bs->notify;
        select(undef, undef, undef, 0.1);
    }
    _exit(0);
}

$stop_w = EV::timer 1.5, 0, sub { undef $io_w; undef $stop_w };
EV::run;
waitpid($pid, 0);
printf "done, count=%d\n", $bs->count;
