#!/usr/bin/env perl
# Single-process benchmark: intern (cold + warm), id_of, string.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Intern::Shared;

my $N = 1_000_000;
my $in = Data::Intern::Shared->new(undef, $N, 32 << 20);
my @words = map { "word-$_" } 0 .. $N - 1;

my $t = time;
$in->intern($_) for @words;
printf "intern (cold):  %.2fM/s\n", $N / (time - $t) / 1e6;

$t = time;
$in->intern($_) for @words;                 # all hits now
printf "intern (warm):  %.2fM/s\n", $N / (time - $t) / 1e6;

$t = time;
$in->id_of($words[int rand $N]) for 1 .. $N;
printf "id_of:          %.2fM/s\n", $N / (time - $t) / 1e6;

$t = time;
$in->string(int rand $N) for 1 .. $N;
printf "string:         %.2fM/s\n", $N / (time - $t) / 1e6;
