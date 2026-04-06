#!/usr/bin/env perl
# Single-process throughput benchmark
use strict;
use warnings;
use Time::HiRes qw(time);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $n = shift || 1_000_000;

sub bench {
    my ($label, $code) = @_;
    my $t0 = time;
    $code->();
    my $elapsed = time - $t0;
    my $rate = $n / $elapsed;
    printf "  %-30s %8.0f/s  (%.3fs)\n", $label, $rate, $elapsed;
}

print "Single-process benchmark, $n ops:\n\n";

# ---- Int queue ----
{
    my $q = Data::Queue::Shared::Int->new(undef, $n < 1048576 ? 1048576 : 2 * $n);

    print "Int (lock-free Vyukov MPMC):\n";

    bench "push" => sub { $q->push($_) for 1..$n };
    bench "pop" => sub { $q->pop for 1..$n };

    bench "push+pop interleaved" => sub {
        for (1..$n) { $q->push($_); $q->pop }
    };

    # Batch
    my $batch = 100;
    my $iters = int($n / $batch);
    bench "push_multi($batch)" => sub {
        my @vals = (1..$batch);
        $q->push_multi(@vals) for 1..$iters;
    };
    bench "pop_multi($batch)" => sub {
        $q->pop_multi($batch) for 1..$iters;
    };

    bench "drain($batch)" => sub {
        my @vals = (1..$batch);
        for (1..$iters) {
            $q->push_multi(@vals);
            $q->drain($batch);
        }
    };

    bench "peek (non-destructive)" => sub {
        $q->push(42);
        $q->peek for 1..$n;
        $q->pop;
    };
}

print "\n";

# ---- Str queue (short strings) ----
{
    my $q = Data::Queue::Shared::Str->new(undef, $n < 1048576 ? 1048576 : 2 * $n);
    my $short = "hello";  # 5 bytes

    print "Str (mutex, short strings ~5B):\n";

    bench "push" => sub { $q->push($short) for 1..$n };
    bench "pop" => sub { $q->pop for 1..$n };

    bench "push+pop interleaved" => sub {
        for (1..$n) { $q->push($short); $q->pop }
    };

    my $batch = 100;
    my $iters = int($n / $batch);
    bench "push_multi($batch)" => sub {
        my @vals = ($short) x $batch;
        $q->push_multi(@vals) for 1..$iters;
    };
    bench "pop_multi($batch)" => sub {
        $q->pop_multi($batch) for 1..$iters;
    };
}

print "\n";

# ---- Str queue (medium strings) ----
{
    my $q = Data::Queue::Shared::Str->new(undef, $n < 1048576 ? 1048576 : 2 * $n);
    my $med = "x" x 100;  # 100 bytes

    print "Str (mutex, medium strings ~100B):\n";

    bench "push" => sub { $q->push($med) for 1..$n };
    bench "pop" => sub { $q->pop for 1..$n };

    bench "push+pop interleaved" => sub {
        for (1..$n) { $q->push($med); $q->pop }
    };
}

print "\n";

# ---- Deque ops ----
{
    my $q = Data::Queue::Shared::Str->new(undef, $n < 1048576 ? 1048576 : 2 * $n);
    my $s = "deque";

    print "Str deque ops:\n";

    bench "push_front" => sub { $q->push_front($s) for 1..$n };
    bench "pop_back" => sub { $q->pop_back for 1..$n };

    bench "push_front+pop_back interleaved" => sub {
        for (1..$n) { $q->push_front($s); $q->pop_back }
    };
}
