use v5.40;
use Test2::V0;
use lib '../lib';
use Algorithm::Kademlia;
#
my $local = pack 'H*', '00' x 32;
my $rt    = Algorithm::Kademlia::RoutingTable->new( local_id_bin => $local, k => 2 );
#
subtest 'Add/Retrieve Peer' => sub {
    my $peer = pack 'H*', 'ff' . ( '00' x 31 );
    $rt->add_peer( $peer, { name => 'Alice' } );
    my @closest = $rt->find_closest($peer);
    is $closest[0]{data}{name}, 'Alice', 'Stored and retrieved peer';
};
subtest 'Eviction Policy' => sub {

    # k is 2
    # All these share '01' as the first byte, so they all fall into bucket 248
    my $p1 = pack 'H*', '01' . ( '00' x 31 );
    my $p2 = pack 'H*', '01' . ( '01' . ( '00' x 30 ) );
    my $p3 = pack 'H*', '01' . ( '02' . ( '00' x 30 ) );
    is $rt->add_peer( $p1, { n => 1 } ), undef, 'Added p1 to bucket 248';
    is $rt->add_peer( $p2, { n => 2 } ), undef, 'Added p2 to bucket 248';
    my $stale = $rt->add_peer( $p3, { n => 3 } );
    ok $stale, 'Bucket full, returns stale candidate';
    is $stale->{id}, $p1, 'p1 is the oldest (LRS)';
    $rt->evict_peer($p1);
    is $rt->add_peer( $p3, { n => 3 } ), undef, 'Successfully added p3 after evicting p1';
    my @closest = $rt->find_closest($p3);

    # Should have p2 and p3 now
    my %ids = map { $_->{id} => 1 } @closest;
    ok $ids{$p2},  'p2 still present';
    ok $ids{$p3},  'p3 now present';
    ok !$ids{$p1}, 'p1 gone';
};
done_testing;
