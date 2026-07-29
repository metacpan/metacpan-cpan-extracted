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
use Data::TopK::Shared;

# Find the heaviest keys of a skewed stream with a fixed number of counters.
# A handful of "hot" keys appear often; a long tail of "cold" keys appear once
# or twice.  With far fewer counters than distinct keys, Space-Saving still
# recovers the hot set exactly and bounds the error on everything else.

my $capacity = 32;                         # only 32 counters...
my $tk = Data::TopK::Shared->new(undef, $capacity);

# deterministic pseudo-random stream (no non-core deps)
my $seed = 12345;
sub rnd { $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; $seed / 0x7fffffff }

my @hot = map { "hot-$_" } 1 .. 8;         # 8 genuine heavy hitters
my %true;
for (1 .. 100_000) {
    my $key = rnd() < 0.6                   # 60% of traffic is one of the hot keys
        ? $hot[ int(rnd() * @hot) ]
        : "cold-" . int(rnd() * 50_000);    # ...the rest is a long cold tail
    $tk->add($key);
    $true{$key}++;
}

printf "fed %d observations, %d distinct hot keys, ~%d distinct total; %d counters\n\n",
    $tk->seen, scalar(@hot), scalar(keys %true), $capacity;

printf "%-12s %8s %8s   %s\n", "key", "est", "error", "true";
printf "%-12s %8s %8s   %s\n", "-" x 12, "-" x 8, "-" x 8, "-" x 8;
for my $h ($tk->top(10)) {
    printf "%-12s %8d %8d   %d\n",
        $h->{key}, $h->{count}, $h->{error}, $true{ $h->{key} } // 0;
}
