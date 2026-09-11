#!/usr/bin/perl

# t/amberdb/amberdb_junk_tiered.t - Tests for AmberDB 3-Stream Dual-Tier (Base, A:, B:) Indexing System

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';
use AmberDB;
use AmberDB::Tools;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0 }
);

# 1. Setup Producer schema (catalog_producer)
$adb->table_attr( 'catalog_producer', {
    record_index => 1,
    blocks       => [
        { id => "id",    type => "auto_id" }, # 0
        { id => "level", type => "text" },    # 1
        { id => "name",  type => "text" },    # 2
        # blocks 3..13
        ( map { { id => "res_$_", type => "text" } } 3..13 ),
        { id => "statu", type => "text" },    # 14: Satış Statüsü (1: Aktif, 0: Pasif)
    ]
} );

# 2. Setup Product schema (catalog_product) with use_junk and junk_rules
$adb->table_attr( 'catalog_product', {
    record_index => 1,
    use_junk     => 1,
    junk_rules   => [
        [ 20, "ne", 1 ],     # Kural 1: Ürünün kendi satış statüsü 1 değilse -> JUNK
        [ "2->14", "ne", 1 ] # Kural 2: Ürünün üreticisinin (blok 2) 14. alanı 1 değilse -> JUNK
    ],
    search_block => [ 4 ],    # Block 4: name (searchable)
    match_block  => [ 1, 2 ], # Block 1: cat, Block 2: firm
    sort_block   => [ 4 ],    # Block 4: name (sortable)
    blocks       => [
        { id => "id",           type => "auto_id" }, # 0
        { id => "cat",          type => "text" },    # 1
        { id => "firm",         type => "text", rdbm => "catalog_producer;2" }, # 2
        { id => "auth",         type => "text" },    # 3
        { id => "name",         type => "text" },    # 4
        # blocks 5..19
        ( map { { id => "res_$_", type => "text" } } 5..19 ),
        { id => "sales_status", type => "option" },  # 20: 1: Satışta, 0: Satış Dışı
    ]
} );

# Insert test producers into catalog_producer:
# Producer 1: Aktif (statu = 1)
# Producer 2: Pasif (statu = 0)
my @p1_data = ( 1, "A", "Aktif Yayinevi", (("") x 11), 1 );
my @p2_data = ( 2, "B", "Pasif Yayinevi", (("") x 11), 0 );
$adb->insert_id( 'catalog_producer', @p1_data );
$adb->insert_id( 'catalog_producer', @p2_data );

# ---------------------------------------------------------------------------
subtest '1. Rule evaluation (junk_rules with Direct & RDBM resolution)' => sub {
    plan tests => 4;

    # Case A: Producer is active (1), Product is in sale (20 => 1) -> ACTIVE (junk = 0)
    my @rec_a = ( 101, "Roman", 1, "Yazar A", "Kitap A", (("") x 15), 1 );
    is( $adb->junk_rules( $adb->table_info('catalog_product'), @rec_a ), 0, "Active firm + in-sale product -> Active (junk=0)" );

    # Case B: Producer is active (1), Product is out of sale (20 => 0) -> JUNK (junk = 1)
    my @rec_b = ( 102, "Roman", 1, "Yazar B", "Kitap B", (("") x 15), 0 );
    is( $adb->junk_rules( $adb->table_info('catalog_product'), @rec_b ), 1, "Active firm + out-of-sale product -> Junk (junk=1)" );

    # Case C: Producer is inactive (2), Product is in sale (20 => 1) -> JUNK due to firm rule (2->14)
    my @rec_c = ( 103, "Roman", 2, "Yazar C", "Kitap C", (("") x 15), 1 );
    is( $adb->junk_rules( $adb->table_info('catalog_product'), @rec_c ), 1, "Inactive firm + in-sale product -> Junk (junk=1)" );

    # Case D: Direct array evaluation
    my $tinfo_arr = {
        use_junk   => 1,
        junk_rules => [ [ "2->1", "eq", "test" ] ],
    };
    my @rec_d = ( 104, "Roman", [ "zero", "test" ] );
    is( $adb->junk_rules( $tinfo_arr, @rec_d ), 1, "Nested array matching rule -> Junk (junk=1)" );
};

# ---------------------------------------------------------------------------
subtest '2. CRUD partitioning into Base, A: and B: streams' => sub {
    plan tests => 9;

    my $tpath = $adb->table_path('catalog_product');

    # Insert Product 1 (Active)
    my @p1 = ( "Roman", 1, "Yazar A", "Kitap Alfa", (("") x 15), 1 );
    $adb->insert_id( 'catalog_product', 1, @p1 );

    # Insert Product 2 (Junk due to sales_status=0)
    my @p2 = ( "Roman", 1, "Yazar B", "Kitap Beta", (("") x 15), 0 );
    $adb->insert_id( 'catalog_product', 2, @p2 );

    # Check Base keys vs A:keys vs B:keys in .inx
    my ( undef, @base_ids ) = $adb->index_get( "$tpath.inx", "keys", "ids", 0, 0, 'asc' );
    my ( undef, @a_ids )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @b_ids )    = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );

    is_deeply( \@base_ids, [ 1, 2 ], "Base keys has all records [1, 2]" );
    is_deeply( \@a_ids,    [1],      "A:keys has only active product [1]" );
    is_deeply( \@b_ids,    [2],      "B:keys has only junk product [2]" );

    # Check search words in .src (block 4 is name)
    my ( undef, @base_src_beta ) = $adb->index_get( "$tpath.src", "4:beta", "ids" );
    my ( undef, @a_src_alfa )    = $adb->index_get( "$tpath.src", "A:4:alfa", "ids" );
    my ( undef, @b_src_beta )    = $adb->index_get( "$tpath.src", "B:4:beta", "ids" );

    is_deeply( \@base_src_beta, [2], "Base .src has 4:beta for all records" );
    is_deeply( \@a_src_alfa,    [1], "'alfa' indexed in active A:4:alfa" );
    is_deeply( \@b_src_beta,    [2], "'beta' indexed in junk B:4:beta" );

    # Check fields in .fld (block 1 is Roman)
    my @roman_id = $adb->get_fieldlist( "Roman", $tpath, $adb->table_info('catalog_product'), 1 );
    my ( undef, @base_fld_roman ) = $adb->index_get( "$tpath.fld", "1:$roman_id[0]", "ids", 0, 0, 'asc' );
    my ( undef, @a_fld_roman )    = $adb->index_get( "$tpath.fld", "A:1:$roman_id[0]", "ids", 0, 0, 'asc' );
    my ( undef, @b_fld_roman )    = $adb->index_get( "$tpath.fld", "B:1:$roman_id[0]", "ids", 0, 0, 'asc' );

    is_deeply( \@base_fld_roman, [ 1, 2 ], "Base .fld has all records for Roman category" );
    is_deeply( \@a_fld_roman,    [1],      "A:1:... has active product 1" );
    is_deeply( \@b_fld_roman,    [2],      "B:1:... has junk product 2" );
};

# ---------------------------------------------------------------------------
subtest '3. Automatic Status Transition (junk_transition on modify_id)' => sub {
    plan tests => 6;

    my $tpath = $adb->table_path('catalog_product');

    # Modify Product 1 from Active to Junk (set sales_status to 0)
    my @p1_mod = ( "Roman", 1, "Yazar A", "Kitap Alfa", (("") x 15), 0 );
    $adb->modify_id( 'catalog_product', 1, @p1_mod );

    my ( undef, @base_after ) = $adb->index_get( "$tpath.inx", "keys", "ids", 0, 0, 'asc' );
    my ( undef, @a_after )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @b_after )    = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );

    is_deeply( \@base_after, [ 1, 2 ], "Base keys preserves all records after transition" );
    ok( !grep( { $_ == 1 } @a_after ), "Product 1 removed from A:keys" );
    ok( grep( { $_ == 1 } @b_after ),  "Product 1 added to B:keys" );

    # Modify Product 1 back to Active (set sales_status to 1)
    my @p1_act = ( "Roman", 1, "Yazar A", "Kitap Alfa", (("") x 15), 1 );
    $adb->modify_id( 'catalog_product', 1, @p1_act );

    my ( undef, @base_back ) = $adb->index_get( "$tpath.inx", "keys", "ids", 0, 0, 'asc' );
    my ( undef, @a_back )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @b_back )    = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );

    is_deeply( \@base_back, [ 1, 2 ], "Base keys still intact [1, 2]" );
    ok( grep( { $_ == 1 } @a_back ),  "Product 1 restored to A:keys" );
    ok( !grep( { $_ == 1 } @b_back ), "Product 1 removed from B:keys" );
};

# ---------------------------------------------------------------------------
subtest '4. Query modes & Overrides: ALL/none, A, AB, B, BA across APIs' => sub {
    plan tests => 12;

    # Current state: Product 1 is Active, Product 2 is Junk

    # 4.1 read_all with jnktype
    my @res_a    = $adb->read_all( 'catalog_product', jnktype => 'A', keys_only => 1 );
    my @res_b    = $adb->read_all( 'catalog_product', jnktype => 'B', keys_only => 1 );
    my @res_ab   = $adb->read_all( 'catalog_product', jnktype => 'AB', keys_only => 1 );
    my @res_ba   = $adb->read_all( 'catalog_product', jnktype => 'BA', keys_only => 1 );
    my @res_all  = $adb->read_all( 'catalog_product', jnktype => 'all', keys_only => 1 );
    my @res_none = $adb->read_all( 'catalog_product', jnktype => 'none', keys_only => 1 );

    is_deeply( \@res_a,    [1],      "read_all jnktype 'A' returns only active [1]" );
    is_deeply( \@res_b,    [2],      "read_all jnktype 'B' returns only junk [2]" );
    is_deeply( \@res_ab,   [ 1, 2 ], "read_all jnktype 'AB' returns active first, then junk [1, 2]" );
    is_deeply( \@res_ba,   [ 2, 1 ], "read_all jnktype 'BA' returns junk first, then active [2, 1]" );
    is_deeply( \@res_all,  [ 2, 1 ], "read_all jnktype 'all' returns Base stream desc [2, 1]" );
    is_deeply( \@res_none, [ 2, 1 ], "read_all jnktype 'none' returns Base stream desc [2, 1]" );

    # 4.2 table_attr override (disabling use_junk)
    $adb->table_attr( 'catalog_product', { use_junk => undef } );
    my @res_no_junk = $adb->read_all( 'catalog_product', keys_only => 1 );
    is_deeply( \@res_no_junk, [ 2, 1 ], "read_all with use_junk disabled falls back to Base stream [2, 1]" );
    # Restore use_junk
    $adb->table_attr( 'catalog_product', { use_junk => 1 } );

    # 4.3 search_table with jnktype
    my ( $cnt_a, @search_a )     = $adb->search_table( 'catalog_product', 'kitap', start => 0, limit => 10, jnktype => 'A' );
    my ( $cnt_b, @search_b )     = $adb->search_table( 'catalog_product', 'kitap', start => 0, limit => 10, jnktype => 'B' );
    my ( $cnt_ab, @search_ab )   = $adb->search_table( 'catalog_product', 'kitap', start => 0, limit => 10, jnktype => 'AB' );
    my ( $cnt_all, @search_all ) = $adb->search_table( 'catalog_product', 'kitap', start => 0, limit => 10, jnktype => 'all' );

    is( $cnt_a,   1, "search_table jnktype 'A' found 1 active record" );
    is( $cnt_b,   1, "search_table jnktype 'B' found 1 junk record" );
    is( $cnt_ab,  2, "search_table jnktype 'AB' found 2 records across active + junk" );
    is( $cnt_all, 2, "search_table jnktype 'all' found 2 records via Base stream" );

    # 4.4 field_fetch with jnktype
    my ( $fld_cnt_a, @ff_a )     = $adb->field_fetch( 'catalog_product', 1, "Roman", jnktype => 'A', keys_only => 1, limit => 10 );
    is( $fld_cnt_a, 1, "field_fetch jnktype 'A' fetched 1 record" );
};

# ---------------------------------------------------------------------------
subtest '5. Rebuilding indexes with AmberDB::Tools (Base + Tiers)' => sub {
    plan tests => 6;

    my $tools = AmberDB::Tools->new( $adb );
    my $tpath = $adb->table_path('catalog_product');

    # Rebuild indexes
    $tools->set_readall('catalog_product');
    $tools->set_search('catalog_product');
    $tools->set_fields('catalog_product');
    $tools->set_sort('catalog_product');

    my ( undef, @base_inx ) = $adb->index_get( "$tpath.inx", "keys", "ids", 0, 0, 'asc' );
    my ( undef, @a_inx )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @b_inx )    = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );

    is_deeply( \@base_inx, [ 1, 2 ], "Tools rebuild created Base keys with all records [1, 2]" );
    is_deeply( \@a_inx,    [1],      "Tools rebuild created A:keys with [1]" );
    is_deeply( \@b_inx,    [2],      "Tools rebuild created B:keys with [2]" );

    my ( undef, @base_src ) = $adb->index_get( "$tpath.src", "4:beta", "ids" );
    my ( undef, @b_src )    = $adb->index_get( "$tpath.src", "B:4:beta", "ids" );
    is_deeply( \@base_src, [2], "Tools rebuild created Base 4:beta in .src" );
    is_deeply( \@b_src,    [2], "Tools rebuild created B:4:beta in .src" );

    my ( undef, @b_sort )   = $adb->index_get( "$tpath.inx", "B:4:keys", "ids" );
    is_deeply( \@b_sort,   [2], "Tools rebuild created B:4:keys in .inx" );
};

# ============================================================
# 6. TRANSACTION (WAL) ROLLBACK COMPLIANCE
# ============================================================
subtest '6. Transaction Rollback Compliance with Base + A: + B: Streams' => sub {
    plan tests => 15;

    my $tpath = $adb->table_path('catalog_product');

    # 1. ROLLBACK OF INSERT (active record 3 + junk record 4)
    my @rec3 = ( "Roman", 1, "Yazar 3", "Kitap 3 Aktif", (("") x 15), 1 );
    my @rec4 = ( "Roman", 1, "Yazar 4", "Kitap 4 Pasif", (("") x 15), 0 );

    $adb->transact_start();
    $adb->insert_id( 'catalog_product', 3, @rec3 ); # Active
    $adb->insert_id( 'catalog_product', 4, @rec4 ); # Junk

    my ( undef, @pre_base ) = $adb->index_get( "$tpath.inx", "keys",   "ids", 0, 0, 'asc' );
    my ( undef, @pre_a )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @pre_b )    = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );
    is_deeply( \@pre_base, [ 1, 2, 3, 4 ], "During txn: Base keys has all [1, 2, 3, 4]" );
    is_deeply( \@pre_a,    [ 1, 3 ],       "During txn: A:keys has [1, 3]" );
    is_deeply( \@pre_b,    [ 2, 4 ],       "During txn: B:keys has [2, 4]" );

    my $rb_res = $adb->transact_rollback();
    is( $rb_res->{status}, 'rollback', "Transaction rolled back" );

    my ( undef, @post_base ) = $adb->index_get( "$tpath.inx", "keys",   "ids", 0, 0, 'asc' );
    my ( undef, @post_a )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @post_b )    = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );
    is_deeply( \@post_base, [ 1, 2 ], "After rollback: Base keys reverted to [1, 2]" );
    is_deeply( \@post_a,    [1],      "After rollback: A:keys reverted to [1]" );
    is_deeply( \@post_b,    [2],      "After rollback: B:keys reverted to [2]" );

    # 2. ROLLBACK OF DELETE (delete active record 1)
    $adb->transact_start();
    $adb->delete_id( 'catalog_product', 1 );
    my ( undef, @del_base ) = $adb->index_get( "$tpath.inx", "keys",   "ids", 0, 0, 'asc' );
    my ( undef, @del_a )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    is_deeply( \@del_base, [2], "During txn: Record 1 removed from Base keys" );
    is_deeply( \@del_a,    [],  "During txn: Record 1 removed from A:keys" );

    $adb->transact_rollback();
    my ( undef, @restored_base ) = $adb->index_get( "$tpath.inx", "keys",   "ids", 0, 0, 'asc' );
    my ( undef, @restored_a )    = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    is_deeply( \@restored_base, [ 1, 2 ], "After rollback: Record 1 restored in Base keys" );
    is_deeply( \@restored_a,    [1],      "After rollback: Record 1 restored in A:keys" );

    # 3. ROLLBACK OF STATUS TRANSITION (modify active 1 -> junk, then rollback)
    my @rec1_junk = ( "Roman", 1, "Yazar A", "Kitap Alfa Pasif", (("") x 15), 0 ); # becomes junk!
    $adb->transact_start();
    $adb->modify_id( 'catalog_product', 1, @rec1_junk );
    my ( undef, @tx_a ) = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @tx_b ) = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );
    is_deeply( \@tx_a, [],     "During txn: Record 1 moved out of A:keys" );
    is_deeply( \@tx_b, [1, 2], "During txn: Record 1 moved into B:keys" );

    $adb->transact_rollback();
    my ( undef, @reverted_a ) = $adb->index_get( "$tpath.inx", "A:keys", "ids", 0, 0, 'asc' );
    my ( undef, @reverted_b ) = $adb->index_get( "$tpath.inx", "B:keys", "ids", 0, 0, 'asc' );
    is_deeply( \@reverted_a, [1], "After rollback: Record 1 transitioned back to A:keys" );
    is_deeply( \@reverted_b, [2], "After rollback: Record 1 removed from B:keys" );
};

done_testing();

