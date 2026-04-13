#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::BitSet::Shared;

my $N = shift || 1_000_000;

sub bench {
    my ($label, $n, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-30s %10.0f/s  (%.3fs)\n", $label, $n / $dt, $dt;
}

printf "Data::BitSet::Shared benchmark (%d ops)\n\n", $N;
my $bs = Data::BitSet::Shared->new(undef, 65536);

bench "set (sequential)", $N, sub { $bs->set($_ % 65536) for 1..$N };
bench "test (sequential)", $N, sub { $bs->test($_ % 65536) for 1..$N };
bench "toggle", $N, sub { $bs->toggle($_ % 65536) for 1..$N };
bench "count (popcount)", $N, sub { $bs->count for 1..$N };
bench "first_set", $N, sub { $bs->first_set for 1..$N };
