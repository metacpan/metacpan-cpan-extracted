#!/usr/bin/perl

# t/amberdb_bin_crop.t - Unit tests for AmberDB::Base pure binary bin_* operations

use 5.016000;
use strict;
use warnings;
use Test::More;

use lib 'lib';
use AmberDB;

my $adb = AmberDB->new();
isa_ok( $adb, 'AmberDB' );

subtest '1. bin_crop with Option 0 (Fastest Unordered / Set Intersection)' => sub {
    plan tests => 4;

    my $buf1 = $adb->bin_encode([ 10, 20, 30, 40, 50 ]);
    my $buf2 = $adb->bin_encode([ 20, 40, 60 ]);
    my $list = [ 50, 20, 99, 40 ];

    # Array input
    my @res_arr = sort { $a <=> $b } $adb->bin_crop( $buf1, $list, 0 );
    is_deeply( \@res_arr, [ 20, 40, 50 ], 'bin_crop with array ref intersects correctly' );

    # Buffer input
    my @res_buf = sort { $a <=> $b } $adb->bin_crop( $buf1, $buf2, 0 );
    is_deeply( \@res_buf, [ 20, 40 ], 'bin_crop with binary buffer intersects correctly' );

    # Disjoint intersection returns empty
    my $disjoint = [ 999, 888 ];
    my @empty = $adb->bin_crop( $buf1, $disjoint, 0 );
    is_deeply( \@empty, [], 'Disjoint set returns empty list' );

    # Scalar context returns packed binary buffer
    my $cropped_buf = $adb->bin_crop( $buf1, $list, 0 );
    ok( !ref($cropped_buf) && length($cropped_buf) == 3 * 8, 'Scalar context returns 8-byte packed buffer' );
};

subtest '2. bin_crop with Option 1 (Preserves Buffer Order)' => sub {
    plan tests => 2;

    # Buffer is ordered ascending: 10, 20, 30, 40, 50
    my $buf = $adb->bin_encode([ 10, 20, 30, 40, 50 ]);
    # List is in different order: 50, 10, 30
    my $list = [ 50, 10, 30 ];

    my @res = $adb->bin_crop( $buf, $list, 1 );
    is_deeply( \@res, [ 10, 30, 50 ], 'Option 1 preserves buffer order for array ref' );

    my $buf_list = $adb->bin_encode([ 50, 10, 30 ]);
    my @res_b = $adb->bin_crop( $buf, $buf_list, 1 );
    is_deeply( \@res_b, [ 10, 30, 50 ], 'Option 1 preserves buffer order for buffer input' );
};

subtest '3. bin_crop with Option 2 (Preserves List / Relevance Order)' => sub {
    plan tests => 2;

    my $buf = $adb->bin_encode([ 10, 20, 30, 40, 50 ]);
    my $list = [ 50, 10, 30 ];

    my @res = $adb->bin_crop( $buf, $list, 2 );
    is_deeply( \@res, [ 50, 10, 30 ], 'Option 2 preserves list order for array ref' );

    my $buf_list = pack( "(Q>)*", 50, 10, 30 );
    my @res_b = $adb->bin_crop( $buf, $buf_list, 2 );
    is_deeply( \@res_b, [ 50, 10, 30 ], 'Option 2 preserves list order for buffer input' );
};

subtest '4. Chained Sequential bin_crop (AND Search Pipeline)' => sub {
    plan tests => 2;

    my $word1_buf = $adb->bin_encode([ 10, 20, 30, 40, 50, 60 ]);
    my $word2_buf = $adb->bin_encode([ 20, 30, 50, 70 ]);
    my $word3_buf = $adb->bin_encode([ 30, 50, 80, 90 ]);

    # Pipeline in binary buffer space without decoding until the end
    my $step1 = $adb->bin_crop( $word2_buf, $word1_buf, 0 );
    my $step2 = $adb->bin_crop( $word3_buf, $step1, 0 );

    my ( undef, @final_ids ) = $adb->bin_decode($step2);
    is_deeply( [ sort { $a <=> $b } @final_ids ], [ 30, 50 ], 'Sequential 3-way bin_crop finds exact intersection' );

    # Early exit in chain
    my $disjoint = $adb->bin_encode([ 999 ]);
    my $empty_step = $adb->bin_crop( $disjoint, $step1, 0 );
    is( length($empty_step), 0, 'Disjoint buffer halts chain with 0 bytes' );
};

subtest '5. Pure Binary bin_union' => sub {
    plan tests => 4;

    my $b1 = $adb->bin_encode([ 10, 30, 50 ]);
    my $b2 = $adb->bin_encode([ 20, 30, 40 ]);

    my @asc = $adb->bin_union( [ $b1, $b2 ] );
    is_deeply( \@asc, [ 10, 20, 30, 40, 50 ], 'bin_union merges and deduplicates asc by default' );

    my @desc = $adb->bin_union( [ $b1, $b2 ], 'desc' );
    is_deeply( \@desc, [ 50, 40, 30, 20, 10 ], 'bin_union with desc merges and deduplicates correctly' );

    # Single buffer fast-path
    my @single = $adb->bin_union( [$b1], 'asc' );
    is_deeply( \@single, [ 10, 30, 50 ], 'Single buffer fast-path preserves IDs' );

    # Scalar context returns packed buffer
    my $u_buf = $adb->bin_union( [ $b1, $b2 ] );
    ok( !ref($u_buf) && length($u_buf) == 5 * 8, 'Scalar context returns packed binary buffer' );
};

subtest '6. bin_add, bin_punch, bin_find, bin_sort, bin_count' => sub {
    plan tests => 7;

    my $buf = $adb->bin_encode([ 10, 20, 40, 50 ]);

    # bin_count
    is( $adb->bin_count($buf), 4, 'bin_count returns 4 records' );

    # bin_find
    is( $adb->bin_find( $buf, 20 ), 1, 'bin_find finds existing ID 20' );
    is( $adb->bin_find( $buf, 99 ), 0, 'bin_find returns 0 for missing ID 99' );

    # bin_add (inserts 30, keeps sorted order)
    my $added = $adb->bin_add( $buf, 30 );
    my ( undef, @add_ids ) = $adb->bin_decode( $added, 0, 0, 'asc' );
    is_deeply( \@add_ids, [ 10, 20, 30, 40, 50 ], 'bin_add inserts and keeps buffer sorted' );

    # bin_add duplicate ignored
    my $no_dup = $adb->bin_add( $added, 20 );
    is( length($no_dup), length($added), 'bin_add duplicate ID does not increase buffer' );

    # bin_punch (removes 30)
    my $punched = $adb->bin_punch( $added, 30 );
    my ( undef, @punch_ids ) = $adb->bin_decode( $punched, 0, 0, 'asc' );
    is_deeply( \@punch_ids, [ 10, 20, 40, 50 ], 'bin_punch removes 30 cleanly' );

    # bin_sort
    my $unsorted = pack( "(Q>)*", 50, 10, 40, 20 );
    my $sorted = $adb->bin_sort($unsorted);
    my ( undef, @sorted_ids ) = $adb->bin_decode( $sorted, 0, 0, 'asc' );
    is_deeply( \@sorted_ids, [ 10, 20, 40, 50 ], 'bin_sort sorts 8-byte chunks in ascending order' );
};

subtest '7. bin_search (Direct Binary Search Index Method)' => sub {
    plan tests => 6;

    my $buf = $adb->bin_encode([ 10, 20, 30, 40, 50 ]);

    is( $adb->bin_search( $buf, 10 ), 0, 'Head element index is 0' );
    is( $adb->bin_search( $buf, 30 ), 2, 'Middle element index is 2' );
    is( $adb->bin_search( $buf, 50 ), 4, 'Tail element index is 4' );
    is( $adb->bin_search( $buf, 99 ), -1, 'Missing element returns -1' );
    is( $adb->bin_search( $buf, 0 ), -1, 'Zero/invalid target returns -1' );
    is( $adb->bin_search( '', 10 ), -1, 'Empty buffer returns -1' );
};

done_testing();
