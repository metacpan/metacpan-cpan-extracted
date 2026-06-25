#!/usr/bin/env perl
use strict;
use warnings;
use POSIX ();
use Data::HashMap::Shared::SI;   # string key (player) -> int64 score

# High-water-mark leaderboard updated concurrently by many workers.
# shm_si_max keeps the highest score per player race-free under a single lock,
# so concurrent submissions never lose an update (unlike a get/compare/put).

my $path  = "/tmp/dhms_leaderboard_$$.shm";
my $board = Data::HashMap::Shared::SI->new($path, 1000);

my @players = qw(alice bob carol dave);
my @pids;
for my $w (1 .. 4) {                          # four workers submitting scores
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        srand($w * 7919 + $$);
        my $b = Data::HashMap::Shared::SI->new($path, 1000);
        for (1 .. 5000) {
            my $player = $players[int rand @players];
            shm_si_max $b, $player, int rand 100_000;   # only the max survives
        }
        POSIX::_exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

my $scores = $board->to_hash;
print "Leaderboard (high scores):\n";
my $rank = 1;
for my $player (sort { $scores->{$b} <=> $scores->{$a} } keys %$scores) {
    printf "  %d. %-6s %d\n", $rank++, $player, $scores->{$player};
}

$board->unlink;
