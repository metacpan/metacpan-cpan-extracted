#########################

use Test::More;
BEGIN { plan tests => 4 };
use Algorithm::Bucketizer;

my @items = (30 .. 39);

my $b = Algorithm::Bucketizer->new(
    algorithm => 'retry',
    maxsize   => 100,
);

    # Three buckets with different sizes
for(qw(100 50 200)) {
    $b->add_bucket(maxsize => $_);
}

for my $item (@items) {
    $b->add_item($item, $item);
}

my @buckets = $b->buckets();

is(join('-', $buckets[0]->items()), "30-31-32",
   "first bucket");

is(join('-', $buckets[1]->items()), "33",
   "second bucket");

is(join('-', $buckets[2]->items()), "34-35-36-37-38",
   "third bucket");

is(join('-', $buckets[3]->items()), "39",
   "fourth bucket");

