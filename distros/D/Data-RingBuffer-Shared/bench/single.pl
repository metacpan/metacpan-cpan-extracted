#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::RingBuffer::Shared;

my $N = shift || 1_000_000;

sub bench {
    my ($label, $n, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-30s %10.0f/s  (%.3fs)\n", $label, $n / $dt, $dt;
}

printf "Data::RingBuffer::Shared benchmark (%d ops)\n\n", $N;
my $r = Data::RingBuffer::Shared::Int->new(undef, 1000);

bench "write", $N, sub { $r->write($_) for 1..$N };
bench "latest", $N, sub { $r->latest for 1..$N };
bench "latest(10)", $N, sub { $r->latest(10) for 1..$N };
bench "read_seq", $N, sub { $r->read_seq($_ % 1000) for 1..$N };

print "\nF64:\n";
my $f = Data::RingBuffer::Shared::F64->new(undef, 1000);
bench "write", $N, sub { $f->write($_ * 0.1) for 1..$N };
bench "latest", $N, sub { $f->latest for 1..$N };
