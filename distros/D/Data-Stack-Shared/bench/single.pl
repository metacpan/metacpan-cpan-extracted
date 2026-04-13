#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Stack::Shared;

my $N = shift || 1_000_000;

sub bench {
    my ($label, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-35s %10.0f/s  (%.3fs)\n", $label, $N / $dt, $dt;
}

printf "Data::Stack::Shared single-process benchmark (%d ops)\n\n", $N;

my $stk = Data::Stack::Shared::Int->new(undef, $N < 1000 ? $N : 1000);

bench "push + pop" => sub {
    for (1..$N) {
        $stk->push(42);
        $stk->pop;
    }
};

bench "push (fill) + pop (drain)" => sub {
    my $cap = $stk->capacity;
    for my $round (1 .. int($N / $cap)) {
        $stk->push($_) for 1..$cap;
        $stk->pop for 1..$cap;
    }
};

bench "peek" => sub {
    $stk->push(1);
    $stk->peek for 1..$N;
    $stk->pop;
};

print "\nStr:\n";
my $ss = Data::Stack::Shared::Str->new(undef, 1000, 64);
my $data = "x" x 48;

bench "push + pop (48B)" => sub {
    for (1..$N) {
        $ss->push($data);
        $ss->pop;
    }
};
