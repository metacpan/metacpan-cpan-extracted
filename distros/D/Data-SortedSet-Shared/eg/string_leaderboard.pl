#!/usr/bin/env perl
# A string-keyed leaderboard: player names as members, scores as the ordering.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
BEGIN {
    unless (eval { require Data::Intern::Shared; 1 }) {
        print "skip: Data::Intern::Shared not installed (string-keyed sets need it)\n";
        exit 0;
    }
}
use Data::SortedSet::Shared::Strings;

my $z = Data::SortedSet::Shared::Strings->new(max => 100_000);
$z->add(@$_) for ['alice', 1500], ['bob', 1800], ['carol', 1200], ['dave', 1800], ['eve', 900];

print "top 3:\n";
my @top = $z->rev_range_by_rank(0, 2, withscores => 1);
my $i = 1;
while (my ($name, $sc) = splice @top, 0, 2) { printf "  %d. %-6s %d\n", $i++, $name, $sc }

printf "bob stands %d of %d\n", $z->rev_rank("bob") + 1, $z->count;
$z->incr("eve", 1000);
printf "after eve +1000: eve ranks %d\n", $z->rev_rank("eve") + 1;

my ($low, $score) = $z->pop_min;
printf "dropped the lowest: %s (%d); %d remain\n", $low, $score, $z->count;
