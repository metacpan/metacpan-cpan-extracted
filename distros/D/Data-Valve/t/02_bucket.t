use strict;
use Test::More (tests => 26);

BEGIN
{
    use_ok("Data::Valve");
}

my $bucket = Data::Valve::Bucket->new(
    interval => 10,
    max_items => 5
);

{
    ok($bucket);
    isa_ok($bucket, "Data::Valve::Bucket");
    ok($bucket->interval == 10, "interval is 10");
}

{
    my $first = $bucket->first;
    ok(! $first );
}

{
    ok($bucket->try_push());
    ok($bucket->try_push());
    ok($bucket->try_push());
    ok($bucket->try_push());
    ok($bucket->try_push());
    my $item = $bucket->first;

    ok($item);
    isa_ok($item, "Data::Valve::BucketItem");
    for(1..4) {
        $item = $item->next;
        ok( $item );
        isa_ok($item, "Data::Valve::BucketItem");
    }

    ok(! $item->next );

    my $serialized = $bucket->serialize();
    like($serialized, qr/^\[(?:(?:[\d\.]+,?))+\]$/, "serialization format ok ($serialized)");

    my $bucket2 = Data::Valve::Bucket->deserialize($serialized, 10, 5);

    is($bucket2->interval, 10, "interval is 10");
    is($bucket2->max_items, 5, "max_items is 5");

    is($bucket2->count, 5);
    $bucket2->reset();
    is($bucket2->count, 0);
}
