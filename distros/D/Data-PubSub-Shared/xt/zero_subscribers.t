use strict;
use warnings;
use Test::More;
use Data::PubSub::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Publishing with no subscribers should be a no-op: no resource leak,
# no error, stats advance only push_ok/publish counter (no "dropped"
# metric explosion because no one is listening).

my $p = Data::PubSub::Shared::Int->new(undef, 16);
my $baseline_mmap = $p->stats->{mmap_size};

for (1..10_000) { $p->publish($_) }

my $s = $p->stats;
is $s->{mmap_size}, $baseline_mmap, 'mmap size unchanged after publishing without subs';

# Now attach a subscriber and verify it sees recent values (per ring-buffer semantics)
my $sub = $p->subscribe;
# One more publish — subscriber should see it
$p->publish(99999);
my $got;
for (1..10) {
    $got = $sub->poll;
    last if defined $got;
}
ok defined $got, 'late-joined subscriber observes a subsequent publish';

done_testing;
