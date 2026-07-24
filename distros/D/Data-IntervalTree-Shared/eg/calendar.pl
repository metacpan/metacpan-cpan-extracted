#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::IntervalTree::Shared;

# A booking calendar: each reservation is a half-open time interval keyed by a
# booking id.  An interval tree answers "what's booked at time T?" (stab) and
# "does a proposed slot clash with anything?" (overlaps) in O(log n + matches),
# instead of scanning every booking.

my $cal = Data::IntervalTree::Shared->new(undef, 100_000);

# add some bookings: [start, end] in minutes-since-midnight, id = booking number
my @bookings = (
    [540,  600, 1],   #  9:00-10:00  room A
    [570,  630, 2],   #  9:30-10:30  room B (overlaps 1)
    [600,  660, 3],   # 10:00-11:00
    [720,  840, 4],   # 12:00-14:00
    [800,  810, 5],   # 13:20-13:30 (inside 4)
    [1380, 1440, 6],  # 23:00-24:00
);
$cal->add(@$_) for @bookings;
printf "%d bookings loaded\n\n", $cal->count;

# what is booked at 9:45 (585)?
my $t = 585;
printf "booked at %02d:%02d:\n", int($t/60), $t%60;
printf "  booking %d  [%02d:%02d - %02d:%02d]\n",
    $_->{id}, int($_->{lo}/60), $_->{lo}%60, int($_->{hi}/60), $_->{hi}%60
    for $cal->stab($t);

# does a proposed 10:15-10:45 (615-645) slot clash with anything?
my ($ps, $pe) = (615, 645);
my @clash = $cal->overlaps($ps, $pe);
printf "\nproposed slot %02d:%02d-%02d:%02d: %s\n",
    int($ps/60), $ps%60, int($pe/60), $pe%60,
    @clash ? "CLASHES with " . join(", ", map { "booking $_->{id}" } @clash) : "free";

# how busy is the lunch block 12:00-14:00 (720-840)?
my @lunch = $cal->overlaps(720, 840);
printf "\nbookings touching 12:00-14:00: %d (%s)\n",
    scalar @lunch, join(", ", map { $_->{id} } @lunch);
