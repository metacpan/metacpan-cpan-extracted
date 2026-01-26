use v5.40;
use lib '../lib';
use Algorithm::Kademlia;
#
my $local_id = pack 'H*', '00' x 32;
my $rt       = Algorithm::Kademlia::RoutingTable->new( local_id_bin => $local_id );

# Fill with some dummy peers
for ( 1 .. 50 ) {
    my $pid = pack 'C*', map { int rand 256 } 1 .. 32;
    $rt->add_peer( $pid, { index => $_ } );
}
my $target  = pack 'H*', 'ff' x 32;
my @closest = $rt->find_closest( $target, 3 );
say 'Top 3 closest peers to FF...:';
say sprintf ' - ID: %s (Peer #%s)', unpack( 'H*', $_->{id} ), $_->{data}{index} for @closest
