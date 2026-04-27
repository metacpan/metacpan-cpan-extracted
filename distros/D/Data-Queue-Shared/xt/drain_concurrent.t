use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# drain() while another process is pushing: must see a consistent snapshot,
# not partial state. Every drained value must have been pushed; no value
# is lost or duplicated.

my $q = Data::Queue::Shared::Str->new(undef, 256, 32);
my $N = 20_000;

my $producer = fork // die;
if ($producer == 0) {
    for (1..$N) {
        while (!$q->push("v$_")) { }
    }
    _exit(0);
}

# Consumer: alternate pop and drain, collect all values
my %seen;
my $total = 0;
while ($total < $N) {
    # sometimes pop, sometimes drain
    if (rand() < 0.5) {
        if (defined(my $v = $q->pop)) {
            $seen{$v}++;
            $total++;
        }
    } else {
        my @batch = $q->drain;
        for (@batch) { $seen{$_}++; $total++ }
    }
}
waitpid($producer, 0);

# Invariants:
# - Every v$i for i=1..$N should appear exactly once
# - No other values
is $total, $N, "total consumed = N";
is scalar(keys %seen), $N, "all N distinct values seen (no dupes, no missing)";
my @dupes = grep { $seen{$_} > 1 } keys %seen;
is scalar(@dupes), 0, "no value received more than once"
    or diag "dupes: @dupes";

done_testing;
