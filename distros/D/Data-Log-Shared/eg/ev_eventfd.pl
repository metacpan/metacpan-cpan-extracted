#!/usr/bin/env perl
# EV event loop: writer appends + notifies, reader tails via EV::io on eventfd
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use EV;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Log::Shared;
$| = 1;

my $log = Data::Log::Shared->new(undef, 100_000);
my $efd = $log->eventfd;

my ($io_w, $stop_w);
my $pos = 0;
my $total = 0;
$io_w = EV::io $efd, EV::READ, sub {
    $log->eventfd_consume;
    while (my ($data, $next) = $log->read_entry($pos)) {
        printf "[tail] %s\n", $data;
        $pos = $next;
        $total++;
    }
};

my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..8) {
        $log->append(sprintf "event %d at %.3f", $i, time);
        $log->notify;
        select(undef, undef, undef, 0.1);
    }
    _exit(0);
}

$stop_w = EV::timer 1.5, 0, sub { undef $io_w; undef $stop_w };
EV::run;
waitpid($pid, 0);

while (my ($data, $next) = $log->read_entry($pos)) {
    printf "[tail] %s\n", $data;
    $pos = $next;
    $total++;
}
printf "done, tailed %d entries\n", $total;
