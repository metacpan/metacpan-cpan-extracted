use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::PubSub::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# A fast publisher fills the ring while a slow subscriber is far behind.
# When the publisher's head wraps past the subscriber's read position,
# unconsumed slots are overwritten — the subscriber must observe a drop
# (lost-messages counter or skipped-positions detection on next poll).

my $cap = 8;          # tiny ring forces overwrite quickly
my $msgs = 100;       # 100 publishes >> 8 capacity
my $p = Data::PubSub::Shared::Int->new(undef, $cap);
my $s = $p->subscribe;

# Publish without polling
$p->publish($_) for 1..$msgs;

# Now drain whatever's still in the ring — should be at most $cap items
my @observed;
while (defined(my $v = $s->poll)) {
    push @observed, $v;
}

cmp_ok scalar(@observed), '<=', $cap,
    "subscriber observed at most capacity ($cap) items, got " . scalar(@observed);
cmp_ok scalar(@observed), '>=', 1,
    "subscriber still reads recent items, got " . scalar(@observed);

# The observed values should be from near the end (most recent)
# (subscriber polls the latest available, not the lost-old items)
my $min = $observed[0];
$min = $_ < $min ? $_ : $min for @observed;
cmp_ok $min, '>', $msgs - $cap * 4,
    "observed values are from the recent tail (min=$min, msgs=$msgs)";

# Stats from publisher: should reflect total publishes
my $stats = $p->stats;
diag "stats: " . join(", ", map "$_=$stats->{$_}", sort keys %$stats);
ok exists $stats->{publish_ok}, 'stats hash has publish_ok counter';
cmp_ok $stats->{publish_ok}, '>=', $msgs, "publish_ok >= $msgs (saw publishes)";

done_testing;
