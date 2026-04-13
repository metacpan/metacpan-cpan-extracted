#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Heap::Shared;

my $N = shift || 500_000;

sub bench {
    my ($label, $n, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-35s %10.0f/s  (%.3fs)\n", $label, $n / $dt, $dt;
}

printf "Data::Heap::Shared benchmark (%d ops)\n\n", $N;

my $h = Data::Heap::Shared->new(undef, $N);

bench "push (sequential priority)", $N, sub {
    $h->push($_, $_) for 1..$N;
};

bench "pop (drain)", $N, sub {
    $h->pop while !$h->is_empty;
};

bench "push+pop (interleaved)", $N, sub {
    for (1..$N) {
        $h->push($_, $_);
        $h->pop;
    }
};

bench "peek", $N, sub {
    $h->push(1, 1);
    $h->peek for 1..$N;
    $h->pop;
};
