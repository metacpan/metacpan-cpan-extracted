#!/usr/bin/env perl
# Leaderboard: add scores, query top-N and a player's rank/standing, bump a
# score, and expire the lowest entries via pop_min.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SortedSet::Shared;

my $z = Data::SortedSet::Shared->new(undef, 100_000);
srand(42);
$z->add($_, int(rand(10000))) for 1 .. 5000;        # player id => score
printf "players: %d\n", $z->count;

# top 5, highest score first, with scores
my @top = $z->rev_range_by_rank(0, 4, withscores => 1);
my $rk  = 1;
print "top 5:\n";
while (my ($id, $sc) = splice @top, 0, 2) { printf "  #%d  player %d  score %d\n", $rk++, $id, $sc }

# a player's standing
my $p  = 2500;
my $rr = $z->rev_rank($p);
printf "player %d: score %d, rank %d of %d (%d ahead)\n",
    $p, $z->score($p), $rr + 1, $z->count, $rr;

# how many in a score band
printf "players scoring 8000..9000: %d\n", $z->count_in_score(8000, 9000);

# bump a score, see the new standing
$z->incr($p, 5000);
printf "after +5000, player %d ranks %d\n", $p, $z->rev_rank($p) + 1;

# expire the 1000 lowest scores
my $dropped = 0;
for (1 .. 1000) { my @x = $z->pop_min; last unless @x; $dropped++ }
printf "expired %d lowest; %d remain\n", $dropped, $z->count;
