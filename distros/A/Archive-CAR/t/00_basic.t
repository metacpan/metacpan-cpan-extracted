use v5.40;
use Test2::V0;
use lib 'lib';
use Archive::CAR;
use Archive::CAR::CID;
use Path::Tiny;
use Digest::SHA;
#
subtest 'CAR v1 roundtrip' => sub {
    my $temp = Path::Tiny->tempfile();

    # Create fake CID and data
    my $raw_cid = pack( 'H*', '01711220' ) . Digest::SHA::sha256('hello world');
    open my $fh, '<', \$raw_cid;
    my $cid    = Archive::CAR::CID->decode($fh);
    my $roots  = [$cid];
    my $blocks = [ { cid => $cid, data => 'hello world' } ];

    # Write
    Archive::CAR->write( $temp->stringify, $roots, $blocks, 1 );

    # Read
    my $car = Archive::CAR->from_file( $temp->stringify );
    is $car->version,           1,             'Correct version';
    is scalar $car->roots->@*,  1,             'One root';
    is $car->roots->[0]->raw,   $cid->raw,     'Root CID matches';
    is scalar $car->blocks->@*, 1,             'One block';
    is $car->blocks->[0]{data}, 'hello world', 'Block data matches';
};
#
subtest 'CAR v2 roundtrip' => sub {
    my $temp = Path::Tiny->tempfile();

    # Create fake CID and data
    my $raw_cid = pack( 'H*', '01711220' ) . Digest::SHA::sha256('foo bar');
    open my $fh, '<', \$raw_cid;
    my $cid    = Archive::CAR::CID->decode($fh);
    my $roots  = [$cid];
    my $blocks = [ { cid => $cid, data => 'foo bar' } ];

    # Write v2
    Archive::CAR->write( $temp->stringify, $roots, $blocks, 2 );

    # Read
    my $car = Archive::CAR->from_file( $temp->stringify );
    is $car->version,           2,         'Correct version';
    is scalar $car->roots->@*,  1,         'One root';
    is $car->blocks->[0]{data}, 'foo bar', 'Block data matches';
};
#
done_testing();
