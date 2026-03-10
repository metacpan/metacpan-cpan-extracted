use v5.40;
use Test2::V0;
use lib 'lib';
use Archive::CAR;
use Path::Tiny;
use JSON::PP;
use FindBin;
subtest 'CARv1 Fixture' => sub {
    my $fixtures_dir = path($FindBin::Bin)->child('fixture');
    my $car_file     = $fixtures_dir->child('carv1-basic.car');
    my $json_file    = $fixtures_dir->child('carv1-basic.json');
    ok $car_file->exists,  'v1 car file exists';
    ok $json_file->exists, 'v1 json file exists';
    my $expected = decode_json( $json_file->slurp );
    my $car      = Archive::CAR->from_file( $car_file->stringify );
    is $car->version, 1, 'v1 version matches';

    # Compare roots
    is scalar $car->roots->@*, scalar $expected->{header}{roots}->@*, 'Number of roots matches';

    # Compare blocks
    is scalar $car->blocks->@*, scalar $expected->{blocks}->@*, 'Number of blocks matches';
    for my $i ( 0 .. $expected->{blocks}->@* - 1 ) {
        my $e = $expected->{blocks}[$i];
        my $a = $car->blocks->[$i];
        is $a->{offset},      $e->{offset},      "Block $i: offset matches";
        is $a->{length},      $e->{length},      "Block $i: length matches";
        is $a->{blockOffset}, $e->{blockOffset}, "Block $i: blockOffset matches";
        is $a->{blockLength}, $e->{blockLength}, "Block $i: blockLength matches";
        if ( $a->{cid}->version == 1 ) {
            is $a->{cid}->to_string, $e->{cid}{'/'}, "Block $i: CID matches";
        }
    }

    # Round-trip
    my $temp = Path::Tiny->tempfile();
    $car->to_file( $temp->stringify );
    my $car2 = Archive::CAR->from_file( $temp->stringify );
    is $car2->version,           1,                       'Round-trip version matches';
    is scalar $car2->roots->@*,  scalar $car->roots->@*,  'Round-trip roots count matches';
    is scalar $car2->blocks->@*, scalar $car->blocks->@*, 'Round-trip blocks count matches';
};
subtest 'CARv2 Fixture' => sub {
    my $fixtures_dir = path($FindBin::Bin)->child('fixture');
    my $car_file     = $fixtures_dir->child('carv2-basic.car');
    my $json_file    = $fixtures_dir->child('carv2-basic.json');
    ok $car_file->exists,  'v2 car file exists';
    ok $json_file->exists, 'v2 json file exists';
    my $expected = decode_json( $json_file->slurp );
    my $car      = Archive::CAR->from_file( $car_file->stringify );
    is $car->version, 2, 'v2 version matches';

    # Header v2
    my $h = $car->v2_header;
    is $h->{data_offset},  $expected->{header}{dataOffset},  'data_offset matches';
    is $h->{data_size},    $expected->{header}{dataSize},    'data_size matches';
    is $h->{index_offset}, $expected->{header}{indexOffset}, 'index_offset matches';
    if ( $h->{index_offset} > 0 ) {
        ok defined $car->index, 'Index data is present';
    }
    is scalar $car->roots->@*, scalar $expected->{header}{roots}->@*, 'Number of roots matches';

    # Compare blocks
    is scalar $car->blocks->@*, scalar $expected->{blocks}->@*, 'Number of blocks matches';
    for my $i ( 0 .. $expected->{blocks}->@* - 1 ) {
        my $e = $expected->{blocks}[$i];
        my $a = $car->blocks->[$i];
        is $a->{offset},      $e->{offset},      "Block $i: offset matches";
        is $a->{length},      $e->{length},      "Block $i: length matches";
        is $a->{blockOffset}, $e->{blockOffset}, "Block $i: blockOffset matches";
        is $a->{blockLength}, $e->{blockLength}, "Block $i: blockLength matches";
        if ( $a->{cid}->version == 1 ) {
            is $a->{cid}->to_string, $e->{cid}{'/'}, "Block $i: CID matches";
        }
    }

    # Round-trip
    my $temp = Path::Tiny->tempfile();
    $car->to_file( $temp->stringify );
    my $car2 = Archive::CAR->from_file( $temp->stringify );
    is $car2->version,                  2,                              'Round-trip version matches';
    is scalar $car2->roots->@*,         scalar $car->roots->@*,         'Round-trip roots count matches';
    is scalar $car2->blocks->@*,        scalar $car->blocks->@*,        'Round-trip blocks count matches';
    is $car2->v2_header->{data_offset}, $car->v2_header->{data_offset}, 'Round-trip data_offset matches';
};
done_testing();
