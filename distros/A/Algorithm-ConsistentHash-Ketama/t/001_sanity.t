use strict;
use Test::More tests => 24;

use_ok "Algorithm::ConsistentHash::Ketama";

can_ok "Algorithm::ConsistentHash::Ketama", "new", "add_bucket", "remove_bucket", "hash";

{
    my $ketama = Algorithm::ConsistentHash::Ketama->new();
    isa_ok $ketama, "Algorithm::ConsistentHash::Ketama";

    $ketama->add_bucket( "localhost:11211", 900 );
    $ketama->add_bucket( "localhost:11212", 1800 );
    $ketama->add_bucket( "localhost:11213", 3600 );
    $ketama->add_bucket( "localhost:11214", 7200 );

    my @buckets = $ketama->buckets();

    (
        is( scalar @buckets, 4 ) &&
        is( $buckets[0]->label, "localhost:11211" ) &&
        is( $buckets[0]->weight, 900 ) &&
        is( $buckets[1]->label, "localhost:11212" ) &&
        is( $buckets[1]->weight, 1800 ) &&
        is( $buckets[2]->label, "localhost:11213" ) &&
        is( $buckets[2]->weight, 3600 ) &&
        is( $buckets[3]->label, "localhost:11214" ) &&
        is( $buckets[3]->weight, 7200 )
    ) or diag explain \@buckets;

    $ketama->remove_bucket("localhost:11211");
    @buckets = $ketama->buckets();
    (
        is(scalar @buckets, 3) &&
        is( $buckets[0]->label, "localhost:11212" ) &&
        is( $buckets[0]->weight, 1800 ) &&
        is( $buckets[1]->label, "localhost:11213" ) &&
        is( $buckets[1]->weight, 3600 ) &&
        is( $buckets[2]->label, "localhost:11214" ) &&
        is( $buckets[2]->weight, 7200 )
    ) or diag explain \@buckets;

    $ketama->remove_bucket("localhost:11214");
    @buckets = $ketama->buckets();
    (
        is( scalar @buckets, 2 ) &&
        is( $buckets[0]->label, "localhost:11212" ) &&
        is( $buckets[0]->weight, 1800 ) &&
        is( $buckets[1]->label, "localhost:11213" ) &&
        is( $buckets[1]->weight, 3600 ) 
    ) or diag explain \@buckets;
}
