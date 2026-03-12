use v5.40;
use Test2::V0;
use lib '../lib';
use Algorithm::Kademlia qw[xor_distance xor_bucket_index];
subtest 'XOR Distance' => sub {
    my $id1  = pack 'H*', '00' x 32;
    my $id2  = pack 'H*', '01' . ( '00' x 31 );
    my $dist = xor_distance( $id1, $id2 );
    is unpack( 'H*', $dist ), '01' . ( '00' x 31 ), 'Distance correct';
};
subtest 'Bucket Index' => sub {
    my $id1 = pack 'H*', '00' x 32;

    # MSB differs (bit 255 for 32-byte ID)
    my $id2 = pack 'H*', '80' . ( '00' x 31 );
    is xor_bucket_index( $id1, $id2 ), 255, 'Bucket 255 for MSB diff in 32-byte ID';

    # 8th bit from top (bit 248)
    my $id3 = pack 'H*', '01' . ( '00' x 31 );
    is xor_bucket_index( $id1, $id3 ), 248, 'Bucket 248 for bit 8 diff';

    # Last bit (bit 0)
    my $id4 = pack 'H*', ( '00' x 31 ) . '01';
    is xor_bucket_index( $id1, $id4 ), 0, 'Bucket 0 for LSB diff';
};
done_testing;
