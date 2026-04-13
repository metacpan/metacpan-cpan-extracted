#!/usr/bin/env perl
# EV event loop: watcher fires on push/pop via eventfd notification
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use EV;
use POSIX qw(_exit);
use Data::Stack::Shared;
$| = 1;

my $stk = Data::Stack::Shared::Int->new(undef, 20);
my $efd = $stk->eventfd;

my ($io_w, $pop_w, $stop_w);
$io_w = EV::io $efd, EV::READ, sub {
    my $n = $stk->eventfd_consume // return;
    printf "[watch] %d events, size=%d\n", $n, $stk->size;
};

my $pid = fork // die;
if ($pid == 0) {
    $stk->push($_ * 10), $stk->notify, select(undef,undef,undef,0.12) for 1..6;
    _exit(0);
}

$pop_w = EV::timer 0.2, 0.2, sub {
    printf "[pop]   %d\n", $stk->pop while !$stk->is_empty;
};

$stop_w = EV::timer 1.5, 0, sub { undef $io_w; undef $pop_w; undef $stop_w };
EV::run;
waitpid($pid, 0);
printf "done, size=%d\n", $stk->size;
