#!/usr/bin/env perl
# Basic log: append entries, replay from offset, each_entry iterator
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Log::Shared;
$| = 1;

my $log = Data::Log::Shared->new(undef, 4096);

# append entries
$log->append("first entry");
$log->append("second entry");
$log->append("third entry with more data");

printf "entries: %d, tail: %d, available: %d\n\n",
    $log->entry_count, $log->tail_offset, $log->available;

# replay from beginning
printf "replay:\n";
my $pos = 0;
while (my ($data, $next) = $log->read_entry($pos)) {
    printf "  [offset %3d] %s\n", $pos, $data;
    $pos = $next;
}

# each_entry
printf "\neach_entry:\n";
$log->each_entry(sub {
    printf "  [%3d] %s\n", $_[1], $_[0];
});

my $s = $log->stats;
printf "\nstats: appends=%d, tail=%d, data_size=%d\n",
    $s->{appends}, $s->{tail}, $s->{data_size};
