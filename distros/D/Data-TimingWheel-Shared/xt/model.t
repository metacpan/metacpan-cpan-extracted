use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::TimingWheel::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
my $seed = $ENV{TW_MODEL_SEED} // 42;
my $steps = $ENV{TW_MODEL_STEPS} // 5_000;

for my $mode (qw(anonymous file memfd)) {
    for my $slots (1, 8, 17) {
        srand $seed;
        my $path = "$dir/$mode-$slots.tw";
        my $tw = $mode eq 'memfd'
            ? Data::TimingWheel::Shared->new_memfd('model', $slots, 64)
            : Data::TimingWheel::Shared->new($mode eq 'file' ? $path : undef, $slots, 64);
        my (%pending, @stale);
        my ($now, $serial, $step) = (0, 0, 0);
        my $ok = eval {
            for (1 .. $steps) {
                $step = $_;
                my $r = rand;
                if ($r < 0.50 && keys(%pending) < 64) {
                    my $delay = int(rand(100)) - 2;
                    my $payload = 9_223_372_036_854_775_808 + ++$serial;
                    $pending{$payload} = [$tw->add($delay, $payload), $now + ($delay < 1 ? 1 : $delay)];
                } elsif ($r < 0.70 && %pending) {
                    my @p = sort { $a <=> $b } keys %pending;
                    my $p = $p[int rand @p];
                    my $id = $pending{$p}[0];
                    $tw->cancel($id) == 1 or die "cancel failed\n";
                    push @stale, $id;
                    delete $pending{$p};
                } elsif ($r < 0.95) {
                    my $ticks = int rand 6;
                    $now += $ticks;
                    my @expected = sort { $a <=> $b } grep { $pending{$_}[1] <= $now } keys %pending;
                    my @got = $tw->advance($ticks);
                    my $last = 0;
                    for my $p (@got) {
                        exists $pending{$p} or die "unexpected payload $p\n";
                        $pending{$p}[1] >= $last or die "fire order\n";
                        $last = $pending{$p}[1];
                    }
                    join(',', sort { $a <=> $b } @got) eq join(',', @expected) or die "due payloads\n";
                    push @stale, $pending{$_}[0] for @expected;
                    delete $pending{$_} for @expected;
                } elsif ($r < 0.98) {
                    push @stale, map { $_->[0] } values %pending;
                    $tw->clear;
                    %pending = ();
                    $now = 0;
                } elsif ($mode eq 'file') {
                    $tw = Data::TimingWheel::Shared->new($path, 1, 1);
                } elsif ($mode eq 'memfd') {
                    $tw = Data::TimingWheel::Shared->new_from_fd($tw->memfd);
                }
                splice @stale, 0, @stale - 128 if @stale > 128;
                $tw->cancel($stale[int rand @stale]) == 0 or die "stale cancel succeeded\n" if @stale;
                $tw->now == $now or die "clock\n";
                $tw->count == keys(%pending) or die "pending count\n";
                my $s = $tw->stats;
                $s->{cur} == $now % $slots or die "wheel position\n";
                $s->{num_slots} == $slots && $s->{capacity} == 64 or die "geometry\n";
            }
            my @expected = sort { $a <=> $b } keys %pending;
            my @got = $tw->advance(100);
            join(',', sort { $a <=> $b } @got) eq join(',', @expected) or die "final drain\n";
            $tw->count == 0 or die "drained count\n";
            1;
        };
        my $error = $@;
        ok $ok, "$mode, $slots slots agrees with the model ($steps steps, seed $seed)";
        diag "step $step: $error" unless $ok;
    }
}

done_testing;
