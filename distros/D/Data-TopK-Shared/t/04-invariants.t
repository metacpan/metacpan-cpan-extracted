use strict;
use warnings;
use Test::More;
use Data::TopK::Shared;

my @keys = ('', "\0", "a\0b", "\xff", map { "key$_-tail" } 0 .. 19);
for my $decayed (0, 1) {
    for my $cap (1, 2, 3, 7, 32) {
        srand(4217 + $cap);
        my $t = $decayed ? Data::TopK::Shared->new_decayed(undef, $cap, 5, 3)
                         : Data::TopK::Shared->new(undef, $cap, 5);
        my (%true, $now, $seen, $ops, $bad);
        $now = $seen = $ops = 0;
        my $observe = sub {
            my ($key, $ts) = @_;
            if ($decayed) {
                my $next = defined $ts ? ($ts > $now ? $ts : $now) : $now + 1;
                my $factor = 2 ** (-($next - $now) / 3);
                $_ *= $factor for values %true;
                $now = $next;
            }
            $true{substr($key, 0, 5)}++;
            $seen++;
        };
        for my $step (1 .. 1000) {
            if ($step == 503) {
                $t->clear;
                %true = ();
                $now = $seen = 0;
            } elsif ($step % 11 == 0) {
                my @batch = map { $keys[int rand @keys] } 1 .. 7;
                $t->add_many(\@batch);
                $observe->($_) for @batch;
            } else {
                my $key = rand() < 0.5 ? 'hot' : $keys[int rand @keys];
                my $ts = $step % 3 ? $now + int(rand 11) - 2 : undef;
                my $got = defined $ts ? $t->add($key, $ts) : $t->add($key);
                $observe->($key, $ts);
                $bad = 'add return differs from estimate' if $got != $t->estimate($key);
            }
            $ops++;
            next unless $step % 25 == 0 || $step == 503;
            my @top = $t->top;
            my (%tracked, $sum);
            $sum = 0;
            for my $entry (@top) {
                my ($key, $count, $error) = @{$entry}{qw(key count error)};
                $bad = 'duplicate key' if $tracked{$key}++;
                my $eps = 1e-9 * (1 + $count);
                $bad = 'invalid frequency bound' if $error < 0 || $error > $count
                    || $count + $eps < $true{$key} || $count - $error > $true{$key} + $eps;
                $bad = 'lookup differs from snapshot' if $t->estimate($key) != $count
                    || $t->error($key) != $error;
                $sum += $count;
            }
            my $total = 0; $total += $_ for values %true;
            $bad = 'total weight changed' if abs($sum - $total) > 1e-9 * (1 + $total);
            $bad = 'heavy hitter missing' if grep { $true{$_} > $total / $cap + 1e-9
                && !$tracked{$_} } keys %true;
            for my $i (1 .. $#top) {
                $bad = 'top order' if $top[$i-1]{count} < $top[$i]{count}
                    || ($top[$i-1]{count} == $top[$i]{count}
                        && $top[$i-1]{error} > $top[$i]{error});
            }
            my $st = $t->stats;
            $bad = 'incorrect stats' if $st->{seen} != $seen || $st->{ops} != $ops
                || $st->{tracked} != @top || @top > $cap;
            last if $bad;
        }
        ok !$bad, ($decayed ? 'decayed' : 'plain') . " capacity $cap: stream invariants"
            or diag $bad;
    }
}

done_testing;
