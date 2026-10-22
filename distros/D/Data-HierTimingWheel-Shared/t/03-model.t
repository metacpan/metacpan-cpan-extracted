use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::HierTimingWheel::Shared;

my $class = 'Data::HierTimingWheel::Shared';
my $dir = tempdir(CLEANUP => 1);
for my $geometry ([2, 1], [2, 8], [3, 3], [5, 4], [8, 3], [16, 3], [100, 2]) {
    for my $mode (qw(anon file memfd)) {
        my ($slots, $levels) = @$geometry;
        my $path = "$dir/$slots-$levels.htw";
        my $wheel = $mode eq 'memfd' ? $class->new_memfd('model', @$geometry, 64)
                  : $class->new($mode eq 'file' ? $path : undef, @$geometry, 64);
        my $peer = $mode eq 'file' ? $class->new($path, 2, 1, 1)
                 : $mode eq 'memfd' ? $class->new_from_fd($wheel->memfd) : $wheel;
        my $max = $wheel->max_delay;
        my (%pending, @stale);
        my ($now, $payload, $error) = (0, 0, '');
        srand(100 * $slots + $levels);
        eval {
            for (1 .. 1000) {
                my $w = $_ % 2 ? $wheel : $peer;
                my $r = rand;
                if ($r < .5) {
                    my $delay = int rand($max + 1);
                    if (keys(%pending) == 64) {
                        eval { $w->add($delay, 0) };
                        die 'full pool accepted an add' unless $@ =~ /full/;
                    } else {
                        my $p = ++$payload;
                        $pending{$p} = [$w->add($delay, $p), $now + ($delay || 1)];
                    }
                } elsif ($r < .7 && %pending) {
                    my @p = sort { $a <=> $b } keys %pending;
                    my $p = $p[int rand @p];
                    die "cancel failed for $p" unless $w->cancel($pending{$p}[0]);
                    push @stale, $pending{$p}[0];
                    delete $pending{$p};
                } elsif ($r > .99) {
                    push @stale, map { $_->[0] } values %pending;
                    $w->clear;
                    %pending = ();
                    $now = 0;
                } else {
                    my $ticks = int rand 40;
                    my @got = $w->advance($ticks);
                    my @expected = sort { $a <=> $b }
                        grep { $pending{$_}[1] <= $now + $ticks } keys %pending;
                    my @sorted = sort { $a <=> $b } @got;
                    die "tick $now + $ticks: got @sorted, expected @expected"
                        unless "@sorted" eq "@expected";
                    my $last = $now;
                    for my $p (@got) {
                        die 'payloads out of fire order' if $pending{$p}[1] < $last;
                        $last = $pending{$p}[1];
                        push @stale, $pending{$p}[0];
                        delete $pending{$p};
                    }
                    $now += $ticks;
                }
                die 'stale id cancelled a replacement'
                    if @stale && $w->cancel($stale[int rand @stale]);
                die 'wrong count' unless $peer->count == keys %pending;
                die 'wrong clock' unless $peer->now == $now;
            }
            my @got = sort { $a <=> $b } $peer->advance($max);
            my @expected = sort { $a <=> $b } keys %pending;
            die 'final drain lost timers' unless "@got" eq "@expected";
            die 'final drain left timers' if $wheel->count;
            1;
        } or $error = $@;
        ok !$error, "$mode: $slots slots, $levels levels agree with the expiry model";
        diag $error if $error;
        undef $peer;
        undef $wheel;
        unlink $path if $mode eq 'file';
    }
}

done_testing;
