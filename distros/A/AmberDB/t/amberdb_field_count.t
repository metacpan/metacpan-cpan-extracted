#!/usr/bin/env perl
use 5.016;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
use File::Temp qw(tempdir);

use AmberDB;

my $tmp_dir = tempdir( CLEANUP => 1 );
my $adb     = AmberDB->new( path => { dbase_dir => $tmp_dir } );

# ============================================================
# 1. SETUP SCHEMAS & INSERT RECORDS
# ============================================================
subtest '1. Setup Schemas & Seed Data' => sub {
    my $prod_schema = {
        name         => "Catalog Product",
        record_index => 1,
        match_block  => [ 2, 4 ], # block 2: firm, block 4: category
        blocks       => [
            { id => "id",       name => "ID",       type => "auto_id" },
            { id => "title",    name => "Başlık",   type => "text" },
            { id => "firm",     name => "Firma",    type => "num" },
            { id => "price",    name => "Fiyat",    type => "num" },
            { id => "category", name => "Kategori", type => "num" },
        ],
    };
    ok( $adb->table_attr( "catalog_product", $prod_schema ), "Configured catalog_product schema" );

    # Seed data:
    # Firm 45: 3 records (IDs 1, 2, 3)
    # Firm 68: 2 records (IDs 4, 5)
    # Firm 712: 1 record (ID 6)
    # Firm 1254: 4 records (IDs 7, 8, 9, 10)
    $adb->insert_id( "catalog_product", 1,  "Ürün 1",  45,   100, 10 );
    $adb->insert_id( "catalog_product", 2,  "Ürün 2",  45,   120, 10 );
    $adb->insert_id( "catalog_product", 3,  "Ürün 3",  45,   140, 20 );
    $adb->insert_id( "catalog_product", 4,  "Ürün 4",  68,   200, 20 );
    $adb->insert_id( "catalog_product", 5,  "Ürün 5",  68,   250, 30 );
    $adb->insert_id( "catalog_product", 6,  "Ürün 6",  712,  300, 30 );
    $adb->insert_id( "catalog_product", 7,  "Ürün 7",  1254, 400, 10 );
    $adb->insert_id( "catalog_product", 8,  "Ürün 8",  1254, 420, 10 );
    $adb->insert_id( "catalog_product", 9,  "Ürün 9",  1254, 440, 20 );
    $adb->insert_id( "catalog_product", 10, "Ürün 10", 1254, 460, 30 );

    my $tbl_path = $adb->table_path("catalog_product");
    ok( -e "$tbl_path.fld", "Match index .fld file created" );
};

# ============================================================
# 2. ARRAY REF BATCH COUNTING (User's Exact Scenario)
# ============================================================
subtest '2. Array Ref Batch Counting' => sub {
    # Exact query from user:
    # my $result_ref = $adb->field_count("catalog_product", 2, [45, 68, 712, 1254]);
    my $result_ref = $adb->field_count( "catalog_product", 2, [ 45, 68, 712, 1254 ] );
    is( ref($result_ref), 'HASH', "Returns HASH reference" );
    is( $result_ref->{45},   3, "Firm 45 has 3 records" );
    is( $result_ref->{68},   2, "Firm 68 has 2 records" );
    is( $result_ref->{712},  1, "Firm 712 has 1 record" );
    is( $result_ref->{1254}, 4, "Firm 1254 has 4 records" );

    # Test with non-existent keys (should return 0, not undef)
    my $with_missing = $adb->field_count( "catalog_product", 2, [ 45, 9999, 8888 ] );
    is( $with_missing->{45},   3, "Firm 45 still 3" );
    is( $with_missing->{9999}, 0, "Non-existent firm 9999 returns 0" );
    is( $with_missing->{8888}, 0, "Non-existent firm 8888 returns 0" );

    # List context
    my %result_hash = $adb->field_count( "catalog_product", 2, [ 45, 68 ] );
    is( $result_hash{45}, 3, "List context returns hash: 45 => 3" );
    is( $result_hash{68}, 2, "List context returns hash: 68 => 2" );
};

# ============================================================
# 3. SINGLE SCALAR COUNTING
# ============================================================
subtest '3. Single Scalar Counting' => sub {
    my $cnt45 = $adb->field_count( "catalog_product", 2, 45 );
    is( $cnt45, 3, "Single scalar returns integer count 3 for firm 45" );

    my $cnt1254 = $adb->field_count( "catalog_product", 2, 1254 );
    is( $cnt1254, 4, "Single scalar returns integer count 4 for firm 1254" );

    my $cnt_none = $adb->field_count( "catalog_product", 2, 9999 );
    is( $cnt_none, 0, "Single scalar returns 0 for non-existent firm" );

    # Single scalar in ARRAY ref returns HASH ref
    my $single_arr = $adb->field_count( "catalog_product", 2, [45] );
    is( ref($single_arr), 'HASH', "Single value inside arrayref returns hashref" );
    is( $single_arr->{45}, 3, "Single value in arrayref has correct count" );
};

# ============================================================
# 4. BLOCK NAME RESOLUTION (e.g. 'firm' instead of 2)
# ============================================================
subtest '4. Block Name Resolution' => sub {
    my $res_by_name = $adb->field_count( "catalog_product", "firm", [ 45, 68 ] );
    is_deeply( $res_by_name, { 45 => 3, 68 => 2 }, "Block resolved by column name 'firm'" );

    my $cat_by_name = $adb->field_count( "catalog_product", "category", [ 10, 20, 30 ] );
    is( $cat_by_name->{10}, 4, "Category 10 count = 4" );
    is( $cat_by_name->{20}, 3, "Category 20 count = 3" );
    is( $cat_by_name->{30}, 3, "Category 30 count = 3" );
};

# ============================================================
# 5. COMMA-SEPARATED STRING INPUT
# ============================================================
subtest '5. Comma-Separated String Input' => sub {
    my $str_res = $adb->field_count( "catalog_product", 2, "45, 68, 712" );
    is_deeply( $str_res, { 45 => 3, 68 => 2, 712 => 1 }, "Comma-separated string resolves as batch hashref" );
};

# ============================================================
# 6. OMITTED VALUE (COUNT ALL INDEXED VALUES IN BLOCK)
# ============================================================
subtest '6. All Values in Block' => sub {
    my $all_firms = $adb->field_count( "catalog_product", 2 );
    is_deeply( $all_firms, { 45 => 3, 68 => 2, 712 => 1, 1254 => 4 }, "Counts all indexed firms when value is omitted" );
};

# ============================================================
# 7. JUNK / TIERED SUPPORT (use_junk, jnktype => 'ALL' / 'A' / 'B')
# ============================================================
subtest '7. Tiered Junk Support' => sub {
    my $junk_schema = {
        name         => "Junk Product",
        record_index => 1,
        use_junk     => 1,
        junk_rules   => [
            [ 3, "ne", 1 ] # Block 3 (status) != 1 => JUNK
        ],
        match_block  => [ 2 ], # Block 2: vendor
        blocks       => [
            { id => "id",     type => "auto_id" },
            { id => "name",   type => "text" },
            { id => "vendor", type => "num" },
            { id => "status", type => "num" }, # 1 = Active, 0 = Junk
        ],
    };
    ok( $adb->table_attr( "junk_product", $junk_schema ), "Configured junk_product schema" );

    # Vendor 10: 2 Active (status 1), 1 Junk (status 0)
    $adb->insert_id( "junk_product", 1, "P1", 10, 1 ); # Active
    $adb->insert_id( "junk_product", 2, "P2", 10, 1 ); # Active
    $adb->insert_id( "junk_product", 3, "P3", 10, 0 ); # Junk

    # Vendor 20: 1 Active (status 1), 2 Junk (status 0)
    $adb->insert_id( "junk_product", 4, "P4", 20, 1 ); # Active
    $adb->insert_id( "junk_product", 5, "P5", 20, 0 ); # Junk
    $adb->insert_id( "junk_product", 6, "P6", 20, 0 ); # Junk

    # Default is ALL (no tier filter)
    my $all_v = $adb->field_count( "junk_product", 2, [ 10, 20 ] );
    is( $all_v->{10}, 3, "Vendor 10 total count (ALL) is 3" );
    is( $all_v->{20}, 3, "Vendor 20 total count (ALL) is 3" );

    # Active tier only: jnktype => 'A'
    my $act_v = $adb->field_count( "junk_product", 2, [ 10, 20 ], { jnktype => 'A' } );
    is( $act_v->{10}, 2, "Vendor 10 active count (A) is 2" );
    is( $act_v->{20}, 1, "Vendor 20 active count (A) is 1" );

    # Junk tier only: jnktype => 'B'
    my $jnk_v = $adb->field_count( "junk_product", 2, [ 10, 20 ], { jnktype => 'B' } );
    is( $jnk_v->{10}, 1, "Vendor 10 junk count (B) is 1" );
    is( $jnk_v->{20}, 2, "Vendor 20 junk count (B) is 2" );

    # Single scalar with jnktype
    is( $adb->field_count( "junk_product", 2, 10, { jnktype => 'A' } ), 2, "Scalar vendor 10 active count is 2" );
    is( $adb->field_count( "junk_product", 2, 10, { jnktype => 'B' } ), 1, "Scalar vendor 10 junk count is 1" );
    is( $adb->field_count( "junk_product", 2, 10 ),                    3, "Scalar vendor 10 ALL count is 3" );
};

# ============================================================
# 8. UNINDEXED TABLE FALLBACK (No .fld File)
# ============================================================
subtest '8. Unindexed Table Fallback' => sub {
    my $unindexed_schema = {
        name         => "Simple Table",
        record_index => 1,
        blocks       => [
            { id => "id",   type => "auto_id" },
            { id => "name", type => "text" },
            { id => "dept", type => "text" },
        ],
    };
    ok( $adb->table_attr( "simple_staff", $unindexed_schema ), "Configured simple_staff schema (no match_block)" );

    $adb->insert_id( "simple_staff", 1, "Ali",   "IT" );
    $adb->insert_id( "simple_staff", 2, "Veli",  "IT" );
    $adb->insert_id( "simple_staff", 3, "Ayşe",  "HR" );
    $adb->insert_id( "simple_staff", 4, "Fatma", "Sales" );

    my $unidx_path = $adb->table_path("simple_staff");
    ok( !-e "$unidx_path.fld", "No .fld file for unindexed table" );

    my $counts = $adb->field_count( "simple_staff", 2, [ "IT", "HR", "Sales", "Finance" ] );
    is( $counts->{IT},      2, "Fallback correctly counts IT: 2" );
    is( $counts->{HR},      1, "Fallback correctly counts HR: 1" );
    is( $counts->{Sales},   1, "Fallback correctly counts Sales: 1" );
    is( $counts->{Finance}, 0, "Fallback returns 0 for Finance" );

    is( $adb->field_count( "simple_staff", 2, "IT" ), 2, "Scalar fallback count for IT is 2" );
};

done_testing();
