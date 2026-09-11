#!/usr/bin/perl

# t/amberdb/amberdb_junk_facet_integration.t - Comprehensive test for decoupled Facet & Junk integration

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0 }
);

# Schema: use_junk + use_facet together
$adb->table_attr( 'catalog_product', {
    record_index => 1,
    use_junk     => 1,
    use_facet    => 1,
    junk_rules   => [ [ 20, "ne", 1 ] ],      # status != 1 -> junk
    facet_rules  => [ [ 20, "eq", 1 ] ],      # status == 1 -> facet aktif
    facet_block  => [
        { blk => 1, id => 'cat',   label => 'Kategori' },
        { blk => 2, id => 'brand', label => 'Marka' },
    ],
    match_block  => [ 1, 2 ],
    blocks       => [
        { id => "id",     type => "auto_id" }, # 0
        { id => "cat",    type => "text" },    # 1
        { id => "brand",  type => "text" },    # 2
        ( map { { id => "res_$_", type => "text" } } 3..19 ),
        { id => "status", type => "option" },  # 20
    ]
} );

my $tpath = $adb->table_path('catalog_product');

# ---------------------------------------------------------------------------
subtest '1. Insert active product (status=1)' => sub {
    plan tests => 4;

    $adb->insert_id( 'catalog_product', 101, 'Telefon', 'Apple', ('') x 17, 1 );

    my ( undef, @base_ids ) = $adb->index_get( "$tpath.inx", "keys" );
    my ( undef, @a_ids )    = $adb->index_get( "$tpath.inx", "A:keys" );
    my ( undef, @fac_ids )  = $adb->index_get( "$tpath.fac", "active" );
    my ($fac_101)           = $adb->index_get( "$tpath.fac", "1:101", 'raw' );

    is_deeply( \@base_ids, [101], "Active product in Base .inx" );
    is_deeply( \@a_ids,    [101], "Active product in A:keys" );
    ok( grep( { $_ == 101 } @fac_ids ), "Active product in .fac" );
    ok( defined $fac_101 && $fac_101 ne '', "Product 101 indexed in block 1 .fac" );
};

# ---------------------------------------------------------------------------
subtest '2. Transition Active -> Junk via modify_id (status=0)' => sub {
    plan tests => 5;

    $adb->modify_id( 'catalog_product', 101, 'Telefon', 'Apple', ('') x 17, 0 );

    my ( undef, @base_after ) = $adb->index_get( "$tpath.inx", "keys" );
    my ( undef, @a_after )    = $adb->index_get( "$tpath.inx", "A:keys" );
    my ( undef, @b_after )    = $adb->index_get( "$tpath.inx", "B:keys" );
    my ( undef, @fac_after )  = $adb->index_get( "$tpath.fac", "active" );
    my ($fac_101_after)       = $adb->index_get( "$tpath.fac", "1:101", 'raw' );

    ok( grep( { $_ == 101 } @base_after ), "Preserved in Base .inx" );
    ok( !grep( { $_ == 101 } @a_after ),   "Removed from A:keys" );
    ok( grep( { $_ == 101 } @b_after ),    "Added to B:keys in .inx" );
    ok( !grep( { $_ == 101 } @fac_after ), "Removed from .fac active set" );
    ok( !defined $fac_101_after, "Removed from block 1 .fac file" );
};

# ---------------------------------------------------------------------------
subtest '3. Transition Junk -> Active via modify_id (status=1)' => sub {
    plan tests => 5;

    $adb->modify_id( 'catalog_product', 101, 'Telefon', 'Apple', ('') x 17, 1 );

    my ( undef, @base_back ) = $adb->index_get( "$tpath.inx", "keys" );
    my ( undef, @a_back )    = $adb->index_get( "$tpath.inx", "A:keys" );
    my ( undef, @b_back )    = $adb->index_get( "$tpath.inx", "B:keys" );
    my ( undef, @fac_back )  = $adb->index_get( "$tpath.fac", "active" );
    my ($fac_101_back)       = $adb->index_get( "$tpath.fac", "1:101", 'raw' );

    ok( grep( { $_ == 101 } @base_back ), "Preserved in Base .inx" );
    ok( grep( { $_ == 101 } @a_back ),    "Restored to A:keys" );
    ok( !grep( { $_ == 101 } @b_back ),   "Removed from B:keys in .inx" );
    ok( grep( { $_ == 101 } @fac_back ),  "Restored to .fac active set" );
    ok( defined $fac_101_back && $fac_101_back ne '', "Restored in block 1 .fac file" );
};

# ---------------------------------------------------------------------------
subtest '4. Insert product initially as Junk (status=0)' => sub {
    plan tests => 4;

    $adb->insert_id( 'catalog_product', 102, 'Tablet', 'Samsung', ('') x 17, 0 );

    my ( undef, @base_ids ) = $adb->index_get( "$tpath.inx", "keys" );
    my ( undef, @a_ids )    = $adb->index_get( "$tpath.inx", "A:keys" );
    my ( undef, @b_ids )    = $adb->index_get( "$tpath.inx", "B:keys" );
    my ($fac_102)           = $adb->index_get( "$tpath.fac", "1:102", 'raw' );

    ok( grep( { $_ == 102 } @base_ids ),  "Initial junk product 102 present in Base .inx" );
    ok( !grep( { $_ == 102 } @a_ids ),    "Initial junk product 102 not in A:keys" );
    ok( grep( { $_ == 102 } @b_ids ),     "Initial junk product 102 in B:keys in .inx" );
    ok( !defined $fac_102, "Initial junk product 102 not in .fac" );
};

# ---------------------------------------------------------------------------
subtest '5. Delete product in Junk tier (status=0)' => sub {
    plan tests => 3;

    $adb->delete_id( 'catalog_product', 102 );

    my ( undef, @base_after_del ) = $adb->index_get( "$tpath.inx", "keys" );
    my ( undef, @b_after_del )    = $adb->index_get( "$tpath.inx", "B:keys" );
    my ($fac_102_after_del)       = $adb->index_get( "$tpath.fac", "1:102", 'raw' );

    ok( !grep( { $_ == 102 } @base_after_del ), "Deleted product 102 removed from Base .inx" );
    ok( !grep( { $_ == 102 } @b_after_del ),    "Deleted product 102 removed from B:keys in .inx" );
    ok( !defined $fac_102_after_del, "Deleted product 102 remains absent from .fac" );
};

# ---------------------------------------------------------------------------
subtest '6. Standalone Junk without Facet (use_junk=1, use_facet=0)' => sub {
    plan tests => 4;

    $adb->table_attr( 'junk_only', {
        record_index => 1,
        use_junk     => 1,
        use_facet    => 0,
        junk_rules   => [ [ 2, "ne", 1 ] ], # status != 1 -> junk
        match_block  => [ 1 ],
        blocks       => [
            { id => "id",     type => "auto_id" },
            { id => "name",   type => "text" },
            { id => "status", type => "option" },
        ]
    } );

    my $jpath = $adb->table_path('junk_only');
    $adb->insert_id( 'junk_only', 1, 'Active Item', 1 );
    $adb->insert_id( 'junk_only', 2, 'Junk Item', 0 );

    my ( undef, @base_keys ) = $adb->index_get( "$jpath.inx", "keys" );
    my ( undef, @a_keys )    = $adb->index_get( "$jpath.inx", "A:keys" );
    my ( undef, @b_keys )    = $adb->index_get( "$jpath.inx", "B:keys" );

    is_deeply( [ sort { $a <=> $b } @base_keys ], [ 1, 2 ], "All items in Base .inx" );
    is_deeply( \@a_keys, [1], "Active item 1 in A:keys" );
    is_deeply( \@b_keys, [2], "Junk item 2 in B:keys in .inx" );
    ok( !-e "$jpath.fac", ".fac file not created when use_facet=0" );
};

# ---------------------------------------------------------------------------
subtest '7. Standalone Facet without Junk (use_junk=0, use_facet=1)' => sub {
    plan tests => 4;

    $adb->table_attr( 'facet_only', {
        record_index => 1,
        use_junk     => 0,
        use_facet    => 1,
        facet_rules  => [ [ 2, "eq", 1 ] ], # only status==1 is active in facet
        facet_block  => [ { blk => 1, id => 'cat' } ],
        match_block  => [ 1 ],
        blocks       => [
            { id => "id",     type => "auto_id" },
            { id => "cat",    type => "text" },
            { id => "status", type => "option" },
        ]
    } );

    my $fpath = $adb->table_path('facet_only');
    $adb->insert_id( 'facet_only', 1, 'Electronics', 1 );
    $adb->insert_id( 'facet_only', 2, 'Books', 0 ); # Inactive for facet, but active in main .inx

    my ( undef, @inx_keys )  = $adb->index_get( "$fpath.inx", "keys" );
    my ( undef, @fac_acts )  = $adb->index_get( "$fpath.fac", "active" );
    my ($f1)                 = $adb->index_get( "$fpath.fac", "1:1", 'raw' );
    my ($f2)                 = $adb->index_get( "$fpath.fac", "1:2", 'raw' );

    is_deeply( [ sort { $a <=> $b } @inx_keys ], [ 1, 2 ], "All records in .inx when use_junk=0" );
    is_deeply( \@fac_acts, [1], "Only record 1 in .fac active set" );
    ok( defined $f1 && $f1 ne '', "Record 1 indexed in .fac" );
    ok( !defined $f2, "Record 2 not indexed in .fac due to facet_rules" );
};

# ---------------------------------------------------------------------------
subtest '8. Differing junk_rules and facet_rules' => sub {
    plan tests => 7;

    # junk: status != 1
    # facet: status == 1 AND price >= 50
    $adb->table_attr( 'diff_rules', {
        record_index => 1,
        use_junk     => 1,
        use_facet    => 1,
        junk_rules   => [ [ 3, "ne", 1 ] ],
        facet_rules  => [ [ 3, "eq", 1 ], [ 2, ">=", 50 ] ],
        facet_block  => [ { blk => 1, id => 'cat' } ],
        match_block  => [ 1 ],
        blocks       => [
            { id => "id",     type => "auto_id" },
            { id => "cat",    type => "text" },
            { id => "price",  type => "text" },
            { id => "status", type => "option" },
            ( map { { id => "res_$_", type => "text" } } 4..19 ),
        ]
    } );

    my $dpath = $adb->table_path('diff_rules');
    $adb->insert_id( 'diff_rules', 1, 'Kitap', 100, 1 ); # Active + Facet eligible
    $adb->insert_id( 'diff_rules', 2, 'Defter', 20, 1 ); # Active + Facet ineligible (price < 50)
    $adb->insert_id( 'diff_rules', 3, 'Kalem', 80, 0 );  # Junk (status != 1)

    my ( undef, @base_keys ) = $adb->index_get( "$dpath.inx", "keys" );
    my ( undef, @a_keys )    = $adb->index_get( "$dpath.inx", "A:keys" );
    my ( undef, @b_keys )    = $adb->index_get( "$dpath.inx", "B:keys" );
    my ( undef, @fac_acts )  = $adb->index_get( "$dpath.fac", "active" );
    my ($fac_1)              = $adb->index_get( "$dpath.fac", "1:1", 'raw' );
    my ($fac_2)              = $adb->index_get( "$dpath.fac", "1:2", 'raw' );
    my ($fac_3)              = $adb->index_get( "$dpath.fac", "1:3", 'raw' );

    is_deeply( [ sort { $a <=> $b } @base_keys ], [ 1, 2, 3 ], "All records in Base .inx" );
    is_deeply( [ sort { $a <=> $b } @a_keys ], [ 1, 2 ], "Records 1 & 2 in A:keys" );
    is_deeply( \@b_keys, [3], "Record 3 in B:keys in .inx" );
    is_deeply( \@fac_acts, [1], "Only record 1 in .fac active set" );
    ok( defined $fac_1 && $fac_1 ne '', "Record 1 indexed in block .fac" );
    ok( !defined $fac_2, "Record 2 excluded from .fac due to price < 50" );
    ok( !defined $fac_3, "Record 3 excluded from .fac due to junk status" );
};

# ---------------------------------------------------------------------------
subtest '9. Bulk insert_list and delete_list with Junk and Facet' => sub {
    plan tests => 8;

    my @bulk_records = (
        [ 201, 'Bilgisayar', 'Asus', ('') x 17, 1 ], # Active
        [ 202, 'Telefon',    'Apple', ('') x 17, 0 ], # Junk
        [ 203, 'Aksesuar',   'Sony', ('') x 17, 1 ], # Active
    );

    $adb->insert_list( 'catalog_product', @bulk_records );

    my ( undef, @base_keys ) = $adb->index_get( "$tpath.inx", "keys" );
    my ( undef, @a_keys )    = $adb->index_get( "$tpath.inx", "A:keys" );
    my ( undef, @b_keys )    = $adb->index_get( "$tpath.inx", "B:keys" );
    my ( undef, @fac_acts )  = $adb->index_get( "$tpath.fac", "active" );

    ok( grep( { $_ == 201 } @base_keys ), "Bulk record 201 in Base .inx" );
    ok( grep( { $_ == 201 } @a_keys ),    "Bulk record 201 in A:keys" );
    ok( grep( { $_ == 202 } @b_keys ),    "Bulk record 202 in B:keys in .inx" );
    ok( grep( { $_ == 203 } @fac_acts ), "Bulk record 203 in .fac active" );
    ok( !grep( { $_ == 202 } @fac_acts ), "Bulk record 202 absent from .fac active" );

    # Bulk delete
    $adb->delete_list( 'catalog_product', 201, 202, 203 );

    my ( undef, @base_after_del ) = $adb->index_get( "$tpath.inx", "keys" );
    my ( undef, @a_after_del )    = $adb->index_get( "$tpath.inx", "A:keys" );
    my ( undef, @b_after_del )    = $adb->index_get( "$tpath.inx", "B:keys" );

    ok( !grep( { $_ == 201 || $_ == 203 } @base_after_del ), "Bulk deleted records removed from Base .inx" );
    ok( !grep( { $_ == 201 || $_ == 203 } @a_after_del ),    "Bulk deleted active records removed from A:keys" );
    ok( !grep( { $_ == 202 } @b_after_del ), "Bulk deleted junk records removed from B:keys in .inx" );
};

done_testing();
