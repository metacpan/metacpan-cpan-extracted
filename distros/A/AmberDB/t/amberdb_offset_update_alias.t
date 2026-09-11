#!/usr/bin/perl

use 5.016000;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { language => 'tr', simple => 0 },
);

# ==============================================================================
# SUBTEST 1: Method Availability (can_ok)
# ==============================================================================
subtest '1. can_ok for update_id and update_list' => sub {
    plan tests => 2;
    can_ok( $adb, 'update_id' );
    can_ok( $adb, 'update_list' );
};

# ==============================================================================
# Setup Table Schema and Seed Data
# ==============================================================================
my $tbl = 'test_products';
$adb->table_attr(
    $tbl,
    {
        name         => "Test Products",
        record_index => 1,
        match_block  => [1, 2],
        search_block => [3],
    }
);

# Insert 10 records: (0, category, brand, title, price)
my @inserted_ids;
for my $i ( 1 .. 10 ) {
    my $cat = ( $i % 2 == 0 ) ? 'Electronics' : 'Books';
    my $brand = ( $i <= 5 ) ? 'BrandA' : 'BrandB';
    my $title = "Product Number $i Wireless Device";
    my $price = $i * 100;
    my $id = $adb->insert_id( $tbl, 0, $cat, $brand, $title, $price );
    push @inserted_ids, $id;
}

# ==============================================================================
# SUBTEST 2: update_id alias functionality
# ==============================================================================
subtest '2. update_id functionality' => sub {
    plan tests => 4;

    my $target_id = $inserted_ids[0];
    my @old_rec = $adb->read_id( $tbl, $target_id );
    is( $old_rec[1], 'Books', 'Initial category is Books' );

    # Update using update_id
    my $res = $adb->update_id( $tbl, $target_id, 'Gadgets', 'BrandA', 'Updated Product 1', 999 );
    ok( $res, 'update_id returned success' );

    my @updated_rec = $adb->read_id( $tbl, $target_id );
    is( $updated_rec[1], 'Gadgets', 'Category updated to Gadgets' );
    is( $updated_rec[3], 'Updated Product 1', 'Title updated to Updated Product 1' );
};

# ==============================================================================
# SUBTEST 3: update_list alias functionality
# ==============================================================================
subtest '3. update_list functionality' => sub {
    plan tests => 5;

    my $id2 = $inserted_ids[1];
    my $id3 = $inserted_ids[2];

    my $statu = $adb->update_list(
        $tbl,
        [ $id2, 'BulkCat', 'BrandA', 'Bulk Title 2', 250 ],
        [ $id3, 'BulkCat', 'BrandA', 'Bulk Title 3', 350 ],
    );

    is( ref($statu), 'HASH', 'update_list returns a HASH ref' );
    ok( $statu->{$id2}, 'ID 2 updated successfully in bulk' );
    ok( $statu->{$id3}, 'ID 3 updated successfully in bulk' );

    my @rec2 = $adb->read_id( $tbl, $id2 );
    is( $rec2[1], 'BulkCat', 'ID 2 category is BulkCat' );

    my @rec3 = $adb->read_id( $tbl, $id3 );
    is( $rec3[3], 'Bulk Title 3', 'ID 3 title is Bulk Title 3' );
};

# ==============================================================================
# SUBTEST 4: read_all pagination with offset and backward-compatible start
# ==============================================================================
subtest '4. read_all with offset and start' => sub {
    plan tests => 7;

    # 4.1 Positional (offset = 2, limit = 3)
    my ( $cnt_pos, @recs_pos ) = $adb->read_all( $tbl, 2, 3 );
    is( $cnt_pos, 10, 'Total count is 10' );
    is( scalar @recs_pos, 3, 'Returned 3 records with positional offset' );

    # 4.2 Hash with offset
    my ( $cnt_off, @recs_off ) = $adb->read_all( $tbl, { offset => 2, limit => 3 } );
    is( $cnt_off, 10, 'Total count is 10 with offset option' );
    is( scalar @recs_off, 3, 'Returned 3 records with offset option' );

    # 4.3 Hash with legacy start
    my ( $cnt_st, @recs_st ) = $adb->read_all( $tbl, { start => 2, limit => 3 } );
    is( $cnt_st, 10, 'Total count is 10 with start option' );
    is( scalar @recs_st, 3, 'Returned 3 records with start option' );

    # Verify offset and start yield identical records
    is_deeply( \@recs_off, \@recs_st, 'offset and start produce identical record slices' );
};

# ==============================================================================
# SUBTEST 5: field_fetch pagination with offset and start
# ==============================================================================
subtest '5. field_fetch with offset and start' => sub {
    plan tests => 5;

    # match_block 2 has BrandB for items 6..10 (5 items)
    my ( $cnt_off, @recs_off ) = $adb->field_fetch( $tbl, 2, 'BrandB', { offset => 1, limit => 2 } );
    is( $cnt_off, 5, 'Total matching count for BrandB is 5' );
    is( scalar @recs_off, 2, 'Returned 2 records with offset' );

    my ( $cnt_st, @recs_st ) = $adb->field_fetch( $tbl, 2, 'BrandB', { start => 1, limit => 2 } );
    is( $cnt_st, 5, 'Total matching count with start is 5' );
    is( scalar @recs_st, 2, 'Returned 2 records with start' );

    is_deeply( \@recs_off, \@recs_st, 'field_fetch offset and start produce identical results' );
};

# ==============================================================================
# SUBTEST 6: search_table pagination with offset and start
# ==============================================================================
subtest '6. search_table with offset and start' => sub {
    plan tests => 5;

    # Search for "Wireless" which matches 7 items (3 were updated with other titles)
    my ( $cnt_off, @recs_off ) = $adb->search_table( $tbl, 'Wireless', { offset => 2, limit => 3 } );
    is( $cnt_off, 7, 'Total search count is 7' );
    is( scalar @recs_off, 3, 'Returned 3 search results with offset' );

    my ( $cnt_st, @recs_st ) = $adb->search_table( $tbl, 'Wireless', { start => 2, limit => 3 } );
    is( $cnt_st, 7, 'Total search count with start is 7' );
    is( scalar @recs_st, 3, 'Returned 3 search results with start' );

    is_deeply( \@recs_off, \@recs_st, 'search_table offset and start produce identical results' );
};

# ==============================================================================
# SUBTEST 7: field_filter pagination with offset and start
# ==============================================================================
subtest '7. field_filter with offset and start' => sub {
    plan tests => 5;

    my $res_off = $adb->field_filter( $tbl, { filter => { 2 => 'BrandB' }, offset => 1, limit => 2 } );
    is( $res_off->{count}, 5, 'field_filter total count is 5' );
    is( scalar @{ $res_off->{ids} }, 2, 'field_filter returned 2 IDs with offset' );

    my $res_st = $adb->field_filter( $tbl, { filter => { 2 => 'BrandB' }, start => 1, limit => 2 } );
    is( $res_st->{count}, 5, 'field_filter total count is 5 with start' );
    is( scalar @{ $res_st->{ids} }, 2, 'field_filter returned 2 IDs with start' );

    is_deeply( $res_off->{ids}, $res_st->{ids}, 'field_filter offset and start produce identical IDs' );
};

# ==============================================================================
# SUBTEST 8: recs_cutting and bin_decode unit checks
# ==============================================================================
subtest '8. recs_cutting and bin_decode' => sub {
    plan tests => 4;

    my @items = ( 10, 20, 30, 40, 50 );
    my ( $tot, @slice ) = $adb->recs_cutting( 1, 3, @items );
    is( $tot, 5, 'recs_cutting total is 5' );
    is_deeply( \@slice, [ 20, 30, 40 ], 'recs_cutting slice is [20, 30, 40]' );

    my $buf = $adb->bin_encode( [ 101, 102, 103, 104, 105 ] );
    my ( $bin_tot, @bin_slice ) = $adb->bin_decode( $buf, 2, 2, 'asc' );
    is( $bin_tot, 5, 'bin_decode total count is 5' );
    is_deeply( \@bin_slice, [ 103, 104 ], 'bin_decode sliced IDs [103, 104]' );
};

done_testing();
