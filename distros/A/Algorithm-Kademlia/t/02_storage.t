use v5.40;
use Test2::V0;
use lib '../lib';
use Algorithm::Kademlia;
#
subtest 'Basic Storage' => sub {
    my $storage = Algorithm::Kademlia::Storage->new();
    my $key     = 'foo';
    my $val     = 'bar';
    $storage->put( $key, $val );
    is $storage->get($key)->value, $val,  'Value stored and retrieved';
    is $storage->get('missing'),   undef, 'Missing key returns undef';
};
subtest 'TTL Expiry' => sub {
    my $storage = Algorithm::Kademlia::Storage->new( ttl => 1 );
    $storage->put( 'short', 'life' );
    is $storage->get('short')->value, 'life', 'Immediate retrieval works';
    sleep 2;
    is $storage->get('short'), undef, 'Expired key returns undef';
};
#
done_testing;
