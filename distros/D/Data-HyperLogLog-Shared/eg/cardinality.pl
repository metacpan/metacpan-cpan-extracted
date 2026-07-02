#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::HyperLogLog::Shared;

# Count the number of distinct words in a body of text using a HyperLogLog
# sketch -- a tiny, fixed-size structure that never stores the words themselves.

my $text = <<'TXT';
the quick brown fox jumps over the lazy dog
the dog was not amused so the fox jumped again
the quick brown fox is quick and brown and a fox
TXT

my @words = ($text =~ /(\w+)/g);

my $hll = Data::HyperLogLog::Shared->new;          # default precision 14
$hll->add_many(\@words);

# exact distinct count for comparison
my %seen; $seen{$_}++ for @words;
my $exact = keys %seen;

printf "total words      : %d\n", scalar @words;
printf "distinct (exact) : %d\n", $exact;
printf "distinct (HLL)   : %d\n", $hll->count;

my $st = $hll->stats;
printf "registers        : %d  (precision %d)\n", $st->{registers}, $st->{precision};
printf "memory           : %d bytes\n", $st->{mmap_size};
