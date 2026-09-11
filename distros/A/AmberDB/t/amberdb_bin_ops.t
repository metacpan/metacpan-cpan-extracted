use strict;
use warnings;
use utf8;
use Test::More;
use AmberDB;

my $adb = AmberDB->new();
ok( $adb, "AmberDB instance created" );

subtest "1. bin_count" => sub {
    is( $adb->bin_count(undef), 0, "undef buffer count is 0" );
    is( $adb->bin_count(""), 0, "empty buffer count is 0" );
    is( $adb->bin_count("1234567"), 0, "buffer < 8 bytes count is 0" );

    my $buf = pack("(Q>)*", 1, 2, 3, 4, 5);
    is( $adb->bin_count($buf), 5, "5 packed IDs count is 5" );
};

subtest "2. bin_add" => sub {
    my $buf = '';

    # Add single ID to empty buffer
    $buf = $adb->bin_add($buf, 100);
    is( $adb->bin_count($buf), 1, "Count is 1 after adding 100" );
    my ( undef, @ids ) = $adb->bin_decode($buf);
    is_deeply( \@ids, [100], "Decoded is [100]" );

    # Add duplicate ID (should be ignored)
    $buf = $adb->bin_add($buf, 100);
    is( $adb->bin_count($buf), 1, "Count is still 1 after duplicate add" );

    # Add array of IDs with duplicates
    $buf = $adb->bin_add($buf, [200, 100, 300, 200]);
    is( $adb->bin_count($buf), 3, "Count is 3 after adding [200, 100, 300, 200]" );
    ( undef, @ids ) = $adb->bin_decode($buf, 0, 0, 'asc');
    is_deeply( \@ids, [100, 200, 300], "Decoded is [100, 200, 300]" );

    # Add from undef
    my $buf2 = $adb->bin_add(undef, [10, 20, 20, 30]);
    ( undef, @ids ) = $adb->bin_decode($buf2, 0, 0, 'asc');
    is_deeply( \@ids, [10, 20, 30], "Adding to undef creates clean buffer [10, 20, 30]" );
};

subtest "3. bin_punch" => sub {
    my $buf = pack("(Q>)*", 10, 20, 30, 40, 50);

    # Delete single middle ID (bsearch path)
    $buf = $adb->bin_punch($buf, 30);
    is( $adb->bin_count($buf), 4, "Count is 4 after deleting 30" );
    my ( undef, @ids ) = $adb->bin_decode($buf, 0, 0, 'asc');
    is_deeply( \@ids, [10, 20, 40, 50], "Decoded is [10, 20, 40, 50]" );

    # Delete head and tail IDs
    $buf = $adb->bin_punch($buf, [10, 50]);
    ( undef, @ids ) = $adb->bin_decode($buf, 0, 0, 'asc');
    is_deeply( \@ids, [20, 40], "Decoded is [20, 40]" );

    # Delete non-existent ID
    $buf = $adb->bin_punch($buf, 999);
    is( $adb->bin_count($buf), 2, "Count remains 2 after deleting non-existent ID" );

    # Delete remaining IDs
    $buf = $adb->bin_punch($buf, [20, 40]);
    is( $adb->bin_count($buf), 0, "Buffer is empty after deleting all IDs" );
    is( $buf, '', "Buffer is empty string" );

    # Test unsorted buffer deletion (fallback path)
    my $unsorted = pack("(Q>)*", 50, 10, 40, 20, 30);
    $unsorted = $adb->bin_punch($unsorted, [10, 30]);
    @ids = unpack("(Q>)*", $unsorted);
    is_deeply( \@ids, [50, 40, 20], "Unsorted buffer correctly punched to [50, 40, 20]" );
};

subtest "4. bin_find" => sub {
    my $sorted = pack("(Q>)*", 5, 10, 15, 20, 25);
    ok( $adb->bin_find($sorted, 5), "Found 5 (head)" );
    ok( $adb->bin_find($sorted, 15), "Found 15 (mid)" );
    ok( $adb->bin_find($sorted, 25), "Found 25 (tail)" );
    ok( !$adb->bin_find($sorted, 12), "Not found 12" );
    ok( !$adb->bin_find($sorted, 99), "Not found 99" );

    my $unsorted = pack("(Q>)*", 25, 5, 20, 10, 15);
    ok( $adb->bin_find($unsorted, 5), "Found 5 in unsorted" );
    ok( $adb->bin_find($unsorted, 25), "Found 25 in unsorted" );
    ok( !$adb->bin_find($unsorted, 100), "Not found 100 in unsorted" );
};

subtest "5. bin_sort" => sub {
    my $buf = pack("(Q>)*", 500, 2, 1000000, 45, 1);
    my $sorted = $adb->bin_sort($buf);
    my ( undef, @ids ) = $adb->bin_decode($sorted, 0, 0, 'asc');
    is_deeply( \@ids, [1, 2, 45, 500, 1000000], "Binary sort correctly sorted 64-bit Big-Endian integers" );
};

done_testing();
