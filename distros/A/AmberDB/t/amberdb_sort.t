#!/usr/bin/perl

# t/flatdb_sort.t - Tests for AmberDB binary indexed sorting (.srt)

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(rmtree);
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';

use AmberDB;
use AmberDB::Base::Index;
use AmberDB::Base::Encoder;
use AmberDB::Tools;

subtest 'Sort Methods Existence' => sub {
    plan tests => 7;
    can_ok( 'AmberDB::Base::Index',   'normalize_sort_key' );
    can_ok( 'AmberDB::Base::Encoder', 'bin_encode' );
    can_ok( 'AmberDB::Base::Encoder', 'bin_decode' );
    can_ok( 'AmberDB::Base::Index',   'sort_add' );
    can_ok( 'AmberDB::Base::Index',   'sort_modify' );
    can_ok( 'AmberDB::Base::Index',   'sort_del' );
    can_ok( 'AmberDB::Tools',         'set_sort' );
};

subtest 'Binary Encoding and Decoding (bin_encode / bin_decode)' => sub {
    plan tests => 5;
    my $adb = AmberDB->new();

    my @test_ids = ( 101, 102, 105, 120, 5000 );
    my $encoded  = $adb->bin_encode( \@test_ids );
    ok( length($encoded) == 8 * 5, 'bin_encode produces correct byte length (5 x Q> = 40 bytes)' );

    my ( $count, @decoded ) = $adb->bin_decode( $encoded, 0, 0, 'asc' );
    is( $count, 5, 'bin_decode returns correct total count' );
    is_deeply( \@decoded, \@test_ids, 'bin_decode decodes all IDs in ASC order' );

    my ( undef, @desc_decoded ) = $adb->bin_decode( $encoded, 0, 0, 'desc' );
    is_deeply( \@desc_decoded, [ reverse @test_ids ], 'bin_decode decodes all IDs in DESC order' );

    my ( undef, @slice_decoded ) = $adb->bin_decode( $encoded, 1, 2, 'asc' );
    is_deeply( \@slice_decoded, [ 102, 105 ], 'bin_decode performs O(1) substr slicing (start=1, limit=2)' );
};


subtest 'Sort Key Normalization' => sub {
    plan tests => 15;
    my $adb = AmberDB->new( cfg => { language => 'tr' } );

    # 1. Number normalization (with offset 1e12)
    is( $adb->normalize_sort_key( 0, 'num' ), '1000000000000.000000', 'Zero numeric normalization' );
    is( $adb->normalize_sort_key( 150.5, 'num' ), '1000000000150.500000', 'Positive float normalization' );
    is( $adb->normalize_sort_key( 100, 'num' ), '1000000000100.000000', 'Integer numeric normalization' );
    is( $adb->normalize_sort_key( -500, 'num' ), '0999999999500.000000', 'Negative number normalization' );
    is( $adb->normalize_sort_key( -150.75, 'num' ), '0999999999849.250000', 'Negative decimal float normalization' );

    # Compare numeric string ordering: -500 < -150.75 < 0 < 99.99 < 150.5
    my $norm_neg500 = $adb->normalize_sort_key( -500, 'num' );
    my $norm_neg150 = $adb->normalize_sort_key( -150.75, 'num' );
    my $norm_zero   = $adb->normalize_sort_key( 0, 'num' );
    my $norm_pos99  = $adb->normalize_sort_key( 99.99, 'num' );
    my $norm_pos150 = $adb->normalize_sort_key( 150.5, 'num' );
    ok( ( $norm_neg500 cmp $norm_neg150 ) < 0, '-500 norm < -150.75 norm' );
    ok( ( $norm_neg150 cmp $norm_zero ) < 0, '-150.75 norm < Zero norm' );
    ok( ( $norm_zero cmp $norm_pos99 ) < 0, 'Zero norm < 99.99 norm' );
    ok( ( $norm_pos99 cmp $norm_pos150 ) < 0, '99.99 norm < 150.5 norm' );

    # 2. String normalization & 8-byte Truncation (len => 8)
    is( $adb->normalize_sort_key( 'Buzdolabı NoFrost', 'string', 8 ), 'buzdolab', '8-byte truncation truncates long string to 8 characters' );
    is( $adb->normalize_sort_key( 'Çamaşır Makinesi', 'string', 8 ), 'camasirm', '8-byte Turkish ASCII folding and truncation' );
    is( $adb->normalize_sort_key( 'Kısa', 'string', 8 ), 'kisa    ', 'Shorter string padded with spaces to 8 bytes' );

    # 3. Reference Protection
    is( $adb->normalize_sort_key( ['FirstItem', 'SecondItem'], 'string', 16 ), 'firstitem       ', 'ARRAY ref unwraps first element' );
    is( $adb->normalize_sort_key( { key => 'val' }, 'string', 16 ), '                ', 'HASH ref returns padded empty string' );
    is( $adb->normalize_sort_key( undef, 'string', 16 ), '                ', 'Undef returns padded empty string' );
};

subtest 'AmberDB Sort Integration CRUD & Pagination' => sub {
    plan tests => 15;

    my $temp_dir = tempdir( CLEANUP => 1 );
    my $conf_dir = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    # Write schema file for 'products' table
    # Schema: block 1 = name (string, len 16), block 2 = price (num), block 3 = created_at (date)
    my $schema_file = File::Spec->catfile( $schema_dir, 'products.table' );
    open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
{
    sort_block => [
        1,
        { blk => 2, type => 'num' },
        { blk => 3, type => 'date' },
    ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    # 1. Insert records (insert_id) out of price order
    # Record format: [ id, name, price, created_at ]
    $adb->insert_id( 'products', 101, 'Laptop', 1500, '2026-01-01 10:00:00' );
    $adb->insert_id( 'products', 102, 'Mouse',  25,   '2026-01-02 11:00:00' );
    $adb->insert_id( 'products', 103, 'Monitor', 300,  '2026-01-03 12:00:00' );
    $adb->insert_id( 'products', 104, 'Keyboard', 75,  '2026-01-04 13:00:00' );

    # Verify sort index exists in .inx and no separate .srt is created
    my $table_path = $adb->table_path('products');
    ok( scalar($adb->index_get( "${table_path}.inx", "2:keys" )) && ! -e "${table_path}.srt", 'Sort keys (2:keys) created in .inx (no separate .srt)' );

    # 2. Query default sort (sondan başa / desc): sort => { blk => 2 }
    my @recs_default = $adb->read_all( 'products', sort => { blk => 2 } );
    is( scalar @recs_default, 4, 'Total record count returned correctly in default sort' );
    my @default_ids = map { $_->[0] } @recs_default;
    is_deeply( \@default_ids, [ 101, 103, 104, 102 ], 'sort => { blk => 2 } defaults to sondan başa / DESC (1500, 300, 75, 25)' );

    # 3. Query reverse sort (baştan sona / asc): sort => { blk => 2, reverse => 1 }
    my @recs_rev = $adb->read_all( 'products', sort => { blk => 2, reverse => 1 } );
    my @rev_ids = map { $_->[0] } @recs_rev;
    is_deeply( \@rev_ids, [ 102, 104, 103, 101 ], 'sort => { blk => 2, reverse => 1 } sorts baştan sona / ASC (25, 75, 300, 1500)' );

    # 4. Query scalar block: sort => 2 (desc) vs sort => -2 (asc)
    my @recs_num = $adb->read_all( 'products', sort => 2 );
    is_deeply( [ map { $_->[0] } @recs_num ], [ 101, 103, 104, 102 ], 'sort => 2 defaults to sondan başa / DESC' );
    my @recs_neg = $adb->read_all( 'products', sort => -2 );
    is_deeply( [ map { $_->[0] } @recs_neg ], [ 102, 104, 103, 101 ], 'sort => -2 sorts baştan sona / ASC' );

    # 5. Query sorted ASC by price (block 2) with explicit dir => 'asc'
    my @recs_asc = $adb->read_all( 'products', sort => { blk => 2, dir => 'asc' } );
    my @asc_ids = map { $_->[0] } @recs_asc;
    is_deeply( \@asc_ids, [ 102, 104, 103, 101 ], 'Price dir => asc sorting order correct (25, 75, 300, 1500)' );

    # 6. Pagination test (start = 1, limit = 2 on price ASC) -> Mouse (25) skipped, expect Keyboard (75), Monitor (300)
    my ( $page_cnt, @page_recs ) = $adb->read_all( 'products', 1, 2, sort => { blk => 2, reverse => 1 } );
    is( $page_cnt, 4, 'Total record count correct during pagination' );
    my @page_ids = map { $_->[0] } @page_recs;
    is_deeply( \@page_ids, [ 104, 103 ], 'Paged reverse => 1 query returns correct slice' );

    # 5. Modify record price (Mouse 25 -> 2000)
    $adb->modify_id( 'products', 102, 'Mouse Ultra', 2000, '2026-01-02 11:00:00' );
    my @mod_recs = $adb->read_all( 'products', sort => { blk => 2, dir => 'asc' } );
    my @mod_ids = map { $_->[0] } @mod_recs;
    is_deeply( \@mod_ids, [ 104, 103, 101, 102 ], 'Price ASC updated after modify_id (Mouse moved to highest price)' );

    # 6. Delete record (Monitor 103)
    $adb->delete_id( 'products', 103 );
    my @del_recs = $adb->read_all( 'products', sort => { blk => 2, dir => 'asc' } );
    my @del_ids = map { $_->[0] } @del_recs;
    is_deeply( \@del_ids, [ 104, 101, 102 ], 'Price ASC updated after delete_id (Monitor removed)' );

    # 7. Bulk Insert (insert_list)
    my @bulk = (
        [ 105, 'Headphones', 50,  '2026-01-05 14:00:00' ],
        [ 106, 'Desk Chair', 400, '2026-01-06 15:00:00' ],
    );
    $adb->insert_list( 'products', @bulk );
    my @bulk_recs = $adb->read_all( 'products', sort => { blk => 2, dir => 'asc' } );
    my @bulk_ids = map { $_->[0] } @bulk_recs;
    is_deeply( \@bulk_ids, [ 105, 104, 106, 101, 102 ], 'Price ASC updated after insert_list (50, 75, 400, 1500, 2000)' );

    # 8. String Sorting (block 1 - name)
    my @name_recs = $adb->read_all( 'products', sort => { blk => 1, dir => 'asc' } );
    my @name_ids = map { $_->[0] } @name_recs;
    # Alphabetical order: Desk Chair (106), Headphones (105), Keyboard (104), Laptop (101), Mouse Ultra (102)
    is_deeply( \@name_ids, [ 106, 105, 104, 101, 102 ], 'Name ASC string sorting order correct' );

    # 9. Re-indexing via Tools::set_sort
    my $tools = AmberDB::Tools->new($adb);
    ok( $tools->set_sort('products'), 'Tools::set_sort completed successfully' );
    my @reindex_recs = $adb->read_all( 'products', sort => { blk => 2, dir => 'asc' } );
    my @reindex_ids = map { $_->[0] } @reindex_recs;
    is_deeply( \@reindex_ids, [ 105, 104, 106, 101, 102 ], 'Re-indexed sort binary sequence matches' );
};

subtest 'field_fetch & search_table Sorting Integration' => sub {
    plan tests => 15;

    my $temp_dir = tempdir( CLEANUP => 1 );
    my $conf_dir = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'items.table' );
    open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
{
    sort_block   => [ 1, { blk => 2, type => 'num' } ],
    match_block  => [ 3 ],
    search_block => [ 1 ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    # Insert test items: [ id, name, price, category ]
    $adb->insert_id( 'items', 201, 'Red T-Shirt',   15, 'clothing' );
    $adb->insert_id( 'items', 202, 'Blue T-Shirt',  45, 'clothing' );
    $adb->insert_id( 'items', 203, 'Green T-Shirt', 25, 'clothing' );
    $adb->insert_id( 'items', 204, 'Red Pants',     60, 'clothing' );

    # 1. field_fetch default sort (sondan başa / desc) by price (block 2)
    my @ff_def = $adb->field_fetch( 'items', 3, 'clothing', sort => { blk => 2 } );
    is( scalar @ff_def, 4, 'field_fetch total count correct' );
    my @ff_def_ids = map { $_->[0] } @ff_def;
    is_deeply( \@ff_def_ids, [ 204, 202, 203, 201 ], 'field_fetch sort => { blk => 2 } defaults to DESC (60, 45, 25, 15)' );

    # 2. field_fetch reverse => 1 (baştan sona / asc) by price (block 2)
    my @ff_rev = $adb->field_fetch( 'items', 3, 'clothing', sort => { blk => 2, reverse => 1 } );
    my @ff_rev_ids = map { $_->[0] } @ff_rev;
    is_deeply( \@ff_rev_ids, [ 201, 203, 202, 204 ], 'field_fetch sort => { blk => 2, reverse => 1 } sorts ASC (15, 25, 45, 60)' );

    # 3. field_fetch primary key ID reverse => 1 (baştan sona / asc)
    my @ff_id_rev = $adb->field_fetch( 'items', 3, 'clothing', sort => { reverse => 1 } );
    is_deeply( [ map { $_->[0] } @ff_id_rev ], [ 201, 202, 203, 204 ], 'field_fetch ID reverse => 1 sorts [201..204]' );

    # 4. field_fetch with pagination (start=0, limit=2 reverse => 1)
    my ( undef, @ff_page ) = $adb->field_fetch( 'items', 3, 'clothing', 0, 2, sort => { blk => 2, reverse => 1 } );
    my @ff_page_ids = map { $_->[0] } @ff_page;
    is_deeply( \@ff_page_ids, [ 201, 203 ], 'field_fetch paged reverse => 1 correct' );

    # 5. search_table default sort (sondan başa / desc) by price (block 2) for 't-shirt' (201:15, 202:45, 203:25)
    my @st_def = $adb->search_table( 'items', 't-shirt', sort => { blk => 2 } );
    my @st_def_ids = map { $_->[0] } @st_def;
    is_deeply( \@st_def_ids, [ 202, 203, 201 ], 'search_table sort => { blk => 2 } defaults to DESC (45, 25, 15)' );

    # 6. search_table reverse => 1 (baştan sona / asc) by price (block 2)
    my @st_rev = $adb->search_table( 'items', 't-shirt', sort => { blk => 2, reverse => 1 } );
    my @st_rev_ids = map { $_->[0] } @st_rev;
    is_deeply( \@st_rev_ids, [ 201, 203, 202 ], 'search_table sort => { blk => 2, reverse => 1 } sorts ASC (15, 25, 45)' );

    # 7. search_table primary key ID reverse => 1
    my @st_id_rev = $adb->search_table( 'items', 't-shirt', sort => { reverse => 1 } );
    is_deeply( [ map { $_->[0] } @st_id_rev ], [ 201, 202, 203 ], 'search_table ID reverse => 1 sorts [201, 202, 203]' );

    # 8. Sorting by Block 1 (Name - String with 8-byte length limit) in field_fetch & search_table
    # Names: 201: 'Red T-Shirt', 202: 'Blue T-Shirt', 203: 'Green T-Shirt', 204: 'Red Pants'
    # ASC order: Blue T-Shirt (202), Green T-Shirt (203), Red Pants (204), Red T-Shirt (201)
    my @ff_name_asc = $adb->field_fetch( 'items', 3, 'clothing', sort => { blk => 1, reverse => 1 } );
    is_deeply( [ map { $_->[0] } @ff_name_asc ], [ 202, 203, 204, 201 ], 'field_fetch sort by Name (blk 1) ASC [202, 203, 204, 201]' );

    my @st_name_asc = $adb->search_table( 'items', 't-shirt', sort => { blk => 1, reverse => 1 } );
    is_deeply( [ map { $_->[0] } @st_name_asc ], [ 202, 203, 201 ], 'search_table sort by Name (blk 1) ASC [202, 203, 201]' );

    # 9. CRUD Updates & .srt sync in field_fetch and search_table:
    # A) MODIFY 201: Change Price 15 -> 100 (Becomes highest price)
    $adb->modify_id( 'items', 201, 'Red T-Shirt Exclusive', 100, 'clothing' );
    my @st_mod_price = $adb->search_table( 'items', 't-shirt', sort => { blk => 2 } ); # DESC
    is_deeply( [ map { $_->[0] } @st_mod_price ], [ 201, 202, 203 ], 'After modify_id: 201 moved to highest price in search_table DESC' );

    my @ff_mod_price = $adb->field_fetch( 'items', 3, 'clothing', sort => { blk => 2, reverse => 1 } ); # ASC
    is_deeply( [ map { $_->[0] } @ff_mod_price ], [ 203, 202, 204, 201 ], 'After modify_id: 201 moved to highest price in field_fetch ASC' );

    # B) DELETE 202 (Blue T-Shirt)
    $adb->delete_id( 'items', 202 );
    my @st_del_price = $adb->search_table( 'items', 't-shirt', sort => { blk => 2 } );
    is_deeply( [ map { $_->[0] } @st_del_price ], [ 201, 203 ], 'After delete_id: 202 removed from search_table results' );

    my @ff_del_price = $adb->field_fetch( 'items', 3, 'clothing', sort => { blk => 2, reverse => 1 } );
    is_deeply( [ map { $_->[0] } @ff_del_price ], [ 203, 204, 201 ], 'After delete_id: 202 removed from field_fetch results' );

    # C) INSERT 205 with lowest price (5)
    $adb->insert_id( 'items', 205, 'Yellow T-Shirt', 5, 'clothing' );
    my @st_ins_price = $adb->search_table( 'items', 't-shirt', sort => { blk => 2, reverse => 1 } );
    is_deeply( [ map { $_->[0] } @st_ins_price ], [ 205, 203, 201 ], 'After insert_id: 205 (price 5) appears first in search_table ASC' );
};

subtest 'Primary Key Binary Index (.inx) O(1) Seeking' => sub {
    plan tests => 6;

    my $temp_dir = tempdir( CLEANUP => 1 );
    my $conf_dir = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'orders.table' );
    open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
{
    record_index => 1,
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    for my $id ( 1 .. 50 ) {
        $adb->insert_id( 'orders', $id, "Order #$id", $id * 10 );
    }

    my $table_path = $adb->table_path('orders');
    ok( -e "$table_path.inx", '.inx binary primary key sequence file created' );

    # Page 1: start = 0, limit = 5 (default DESC / newest first: 50..46)
    my ( $cnt1, @p1 ) = $adb->read_all( 'orders', 0, 5 );
    is( $cnt1, 50, 'Total count 50 returned correctly' );
    is_deeply( [ map { $_->[0] } @p1 ], [ 50, 49, 48, 47, 46 ], 'First page (50..46) sliced via bin_decode on .inx (default DESC)' );

    # Page 3: start = 10, limit = 5 (default DESC)
    my ( undef, @p3 ) = $adb->read_all( 'orders', 10, 5 );
    is_deeply( [ map { $_->[0] } @p3 ], [ 40, 39, 38, 37, 36 ], 'Middle page (40..36) sliced via bin_decode on .inx (default DESC)' );

    # Page 1 with explicit dir => 'asc' (oldest first: 1..5)
    my ( undef, @p1_asc ) = $adb->read_all( 'orders', 0, 5, dir => 'asc' );
    is_deeply( [ map { $_->[0] } @p1_asc ], [ 1 .. 5 ], 'First page with dir => asc returns 1..5' );

    # Page 3 with explicit dir => 'asc' (oldest first: 11..15)
    my ( undef, @p3_asc ) = $adb->read_all( 'orders', 10, 5, dir => 'asc' );
    is_deeply( [ map { $_->[0] } @p3_asc ], [ 11 .. 15 ], 'Middle page with dir => asc returns 11..15' );
};

subtest 'convert_tables Batch Conversion' => sub {
    plan tests => 2;
    my $temp_dir = tempdir( CLEANUP => 1 );
    my $conf_dir = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'products.table' );
    open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
{
    record_index => 1,
    match_block  => [ 1 ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    $adb->insert_id( 'products', 1, 'laptop', 'elektronik' );
    $adb->insert_id( 'products', 2, 'telefon', 'elektronik' );

    my $tools = AmberDB::Tools->new($adb);
    my $converted = $tools->convert_tables();
    ok( $converted->{products}, 'convert_tables processed products table' );
    ok( -e File::Spec->catfile( $temp_dir, 'products.fld' ) || -e File::Spec->catfile( $temp_dir, 'table', 'products.fld' ) || -e File::Spec->catfile( $temp_dir, 'tables', 'products.fld' ) || -e File::Spec->catfile( $temp_dir, 'products_1.fld' ), 'products.fld re-created with binary payload' );
};

done_testing();





