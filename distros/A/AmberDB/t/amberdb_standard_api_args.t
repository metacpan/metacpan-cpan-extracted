#!/usr/bin/perl

# t/amberdb_standard_api_args.t - Tests for standardized %args parameter conventions
# across read_all, field_fetch, search_table, field_filter, and field_fltkeys

use 5.016000;
use strict;
use warnings;
use Test::More tests => 9;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0, language => 'tr' }
);

# Schema definition
$adb->table_attr( 'products', {
    record_index => 1,
    blocks       => [
        { name => 'id' },
        { name => 'title' },
        { name => 'category' },
        { name => 'brand' },
        { name => 'price', type => 'num' },
    ],
    match_block  => [ 2, 3 ],
    search_block => [ 1 ],
    sort_block   => [ { blk => 4, type => 'num' } ],
    facet_block  => [ 2, 3 ],
    use_facet    => 1,
} );

# Seed test records: ID, Title, Category, Brand, Price
$adb->insert_id( 'products', 1, 'Apple iPhone 15 Pro Max', 'Smartphones', 'Apple',   1200 );
$adb->insert_id( 'products', 2, 'Samsung Galaxy S24 Ultra', 'Smartphones', 'Samsung', 1100 );
$adb->insert_id( 'products', 3, 'Apple MacBook Pro 16',     'Laptops',     'Apple',   2500 );
$adb->insert_id( 'products', 4, 'Dell XPS 15 Laptop',       'Laptops',     'Dell',    1800 );
$adb->insert_id( 'products', 5, 'Sony WH-1000XM5 Headset',  'Audio',       'Sony',     400 );
$adb->insert_id( 'products', 6, 'Apple AirPods Pro',        'Audio',       'Apple',    250 );

# ---------------------------------------------------------------------------
subtest '1. read_all with standardized \%options' => sub {
    plan tests => 7;

    # Unpaginated
    my @all = $adb->read_all('products');
    is( scalar(@all), 6, 'read_all unpaginated returns all 6 records' );

    # keys_only
    my @all_ids = $adb->read_all('products', { keys_only => 1 });
    is( scalar(@all_ids), 6, 'read_all { keys_only => 1 } returns 6 IDs' );

    # Paginated with offset & limit
    my ($tot, @page) = $adb->read_all('products', { offset => 0, limit => 2 });
    is( $tot, 6, 'Paginated total is 6' );
    is( scalar(@page), 2, 'Page size is 2' );

    # Paginated with sort
    my ($tot_s, @sorted) = $adb->read_all('products', { offset => 0, limit => 3, sort => -4 });
    is( scalar(@sorted), 3, 'Sorted page returns 3 records' );

    # Backward compatibility: positional calls still work
    my ($tot_leg, @page_leg) = $adb->read_all('products', 0, 2);
    is( $tot_leg, 6, 'Legacy positional read_all total count is 6' );
    is( scalar(@page_leg), 2, 'Legacy positional read_all page size is 2' );
};

# ---------------------------------------------------------------------------
subtest '2. field_fetch with standardized \%options' => sub {
    plan tests => 7;

    # Unpaginated
    my @apple_recs = $adb->field_fetch('products', 3, 'Apple');
    is( scalar(@apple_recs), 3, 'field_fetch returns 3 Apple products' );

    # keys_only
    my @apple_ids = $adb->field_fetch('products', 3, 'Apple', { keys_only => 1 });
    is( scalar(@apple_ids), 3, 'field_fetch keys_only returns 3 IDs' );

    # Paginated with offset & limit
    my ($tot, @page) = $adb->field_fetch('products', 3, 'Apple', { offset => 0, limit => 2 });
    is( $tot, 3, 'Paginated total is 3' );
    is( scalar(@page), 2, 'Page limit is 2' );

    # Multi-value
    my @multi = $adb->field_fetch('products', 3, ['Apple', 'Dell']);
    is( scalar(@multi), 4, 'field_fetch with arrayref returns 4 products' );

    # Backward compatibility: legacy positional
    my ($tot_leg, @page_leg) = $adb->field_fetch('products', 3, 'Apple', 0, 2);
    is( $tot_leg, 3, 'Legacy field_fetch total count is 3' );
    is( scalar(@page_leg), 2, 'Legacy field_fetch page count is 2' );
};

# ---------------------------------------------------------------------------
subtest '3. search_table with standardized \%options' => sub {
    plan tests => 6;

    # Unpaginated
    my @search = $adb->search_table('products', 'Apple');
    is( scalar(@search), 3, 'search_table unpaginated returns 3 products' );

    # Paginated with hashref
    my ($tot, @page) = $adb->search_table('products', 'Apple', { offset => 0, limit => 2 });
    is( $tot, 3, 'Paginated search total is 3' );
    is( scalar(@page), 2, 'Page size is 2' );

    # Mode: type => 'or'
    my ($tot_or, @page_or) = $adb->search_table('products', 'Laptop Ultra', { type => 'or', offset => 0, limit => 5 });
    ok( $tot_or >= 2, 'OR search found matching records' );

    # Backward compatibility: legacy positional
    my ($tot_leg, @page_leg) = $adb->search_table('products', 'Apple', 0, 2);
    is( $tot_leg, 3, 'Legacy positional search_table total count is 3' );
    is( scalar(@page_leg), 2, 'Legacy positional search_table page count is 2' );
};

# ---------------------------------------------------------------------------
subtest '4. field_filter with filter, where, match aliases' => sub {
    plan tests => 6;

    # Modern: filter => { ... }
    my $res_flt = $adb->field_filter('products', {
        filter => { 2 => 'Smartphones', 3 => 'Apple' }
    });
    is( $res_flt->{count}, 1, 'field_filter with filter => { ... } matched 1 record' );
    is( $res_flt->{ids}[0], 1, 'Matched iPhone 15 Pro Max (ID 1)' );

    # Alias: where => { ... }
    my $res_wh = $adb->field_filter('products', {
        where => { 2 => 'Smartphones', 3 => 'Apple' }
    });
    is( $res_wh->{count}, 1, 'field_filter with where => { ... } alias matched 1 record' );

    # Alias: match => { ... }
    my $res_match = $adb->field_filter('products', {
        match => { 2 => 'Smartphones', 3 => 'Apple' }
    });
    is( $res_match->{count}, 1, 'field_filter with match => { ... } alias matched 1 record' );

    # Dual-hash invocation: ($table, $filter_hash, \%opts)
    my $res_dual = $adb->field_filter('products', { 3 => 'Apple' }, { limit => 2 });
    is( $res_dual->{count}, 3, 'Dual-hash invocation count is 3' );
    is( scalar(@{ $res_dual->{ids} }), 2, 'Dual-hash invocation limited to 2' );
};

# ---------------------------------------------------------------------------
subtest '5. field_fltkeys with target_block and filter/where/match aliases' => sub {
    plan tests => 4;

    # Standard: target_block & filter
    my $counts = $adb->field_fltkeys('products', {
        target_block => 3,
        filter       => { 2 => 'Smartphones' }
    });
    is( ref($counts), 'HASH', 'field_fltkeys returns HASH' );
    is( $counts->{'Apple'}, 1, 'Brand count for Apple Smartphones is 1' );
    is( $counts->{'Samsung'}, 1, 'Brand count for Samsung Smartphones is 1' );

    # Alias: where => { ... }
    my $counts_wh = $adb->field_fltkeys('products', {
        target_block => 3,
        where        => { 2 => 'Smartphones' }
    });
    is( $counts_wh->{'Apple'}, 1, 'field_fltkeys works with where alias' );
};

# ---------------------------------------------------------------------------
subtest '6. field_fltkeys with base_ids / scope_ids' => sub {
    plan tests => 2;

    # Scoped facet counting (e.g. within search results for ID 1 and 2)
    my $scoped = $adb->field_fltkeys('products', {
        target_block => 3,
        base_ids     => [ 1, 2 ]
    });
    is( $scoped->{'Apple'}, 1, 'Scoped facet count Apple = 1' );
    is( $scoped->{'Samsung'}, 1, 'Scoped facet count Samsung = 1' );
};

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
subtest '7. read_id with standardized \%options and type (first/last/rand)' => sub {
    plan tests => 39;

    # Default read_id
    my @rec = $adb->read_id('products', 1);
    is( $rec[0], 1, 'read_id returns ID 1' );
    is( $rec[1], 'Apple iPhone 15 Pro Max', 'read_id returns correct title' );

    # inflate as string or hashref
    my $inf1 = $adb->read_id('products', 1, 'inflate');
    is( ref($inf1), 'HASH', 'read_id with "inflate" string returns HASH' );

    my $inf_hash = $adb->read_id('products', 1, { inflate => 1 });
    is( ref($inf_hash), 'HASH', 'read_id with inflate => 1 returns HASH' );

    # counter / use_counter and no_counter
    my $cnt_path = $adb->table_path('products') . '.cnt';
    $adb->read_id('products', 1, { counter => 1 });
    my @cnt_res = $adb->table_readid($cnt_path, 1);
    is( $cnt_res[1], 1, 'read_id with counter => 1 increments .cnt counter to 1' );

    $adb->read_id('products', 1, 'no_counter');
    my @cnt_res2 = $adb->table_readid($cnt_path, 1);
    is( $cnt_res2[1], 1, 'read_id with string "no_counter" does not increment counter' );

    # get_deleted / deleted / force
    $adb->table_attr( 'products', { keep_deleted => 1 } );
    $adb->insert_id( 'products', 99, 'Temporary Item', 'Gadgets', 'BrandX', 50 );
    $adb->delete_id( 'products', 99 );
    my @del_normal = $adb->read_id('products', 99);
    is( scalar(@del_normal), 0, 'Deleted record not found normally' );

    my @del_rec = $adb->read_id('products', 99, { deleted => 1 });
    is( $del_rec[0], 99, 'read_id with deleted => 1 finds archived record' );

    my @del_str = $adb->read_id('products', 99, 'deleted');
    is( $del_str[0], 99, 'read_id with string "deleted" finds archived record' );

    # get_links / links / alias
    $adb->table_attr( 'products', { use_alias => 1 } );
    $adb->insert_links( 'products', [ 'phone_alias', 1 ] );
    my @alias_rec = $adb->read_id('products', 'phone_alias', { links => 1 });
    is( $alias_rec[0], 1, 'read_id with links => 1 resolves alias' );

    my @alias_str = $adb->read_id('products', 'phone_alias', 'alias');
    is( $alias_str[0], 1, 'read_id with string "alias" resolves alias' );

    # Merged / duplicate record alias (e.g. record 452 was deleted and linked to 1)
    $adb->insert_links( 'products', [ 452, 1 ] );
    my @merged_str = $adb->read_id('products', 452, 'alias');
    is( $merged_str[0], 1, 'read_id with deleted numeric ID 452 and "alias" returns canonical record 1' );

    my @auto_alias = $adb->read_id('products', 452);
    is( $auto_alias[0], 1, 'read_id with deleted numeric ID 452 resolves automatically via use_alias' );

    # type => "first", "last", "rand" (omitting rid)
    my @first = $adb->read_id('products', { type => 'first' });
    is( $first[0], 1, 'read_id { type => "first" } returns ID 1' );

    my @last = $adb->read_id('products', { type => 'last' });
    is( $last[0], 6, 'read_id { type => "last" } returns ID 6' );

    my $last_inf = $adb->read_id('products', { type => 'last', inflate => 1 });
    is( ref($last_inf), 'HASH', 'read_id { type => "last", inflate => 1 } returns HASH' );
    is( $last_inf->{id}, 6, 'Inflated last record has ID 6' );

    my @rand = $adb->read_id('products', { type => 'rand' });
    ok( $rand[0] && $rand[0] >= 1 && $rand[0] <= 6, 'read_id { type => "rand" } returns valid record' );

    # Consistent 3-argument invocation with dummy rid 0: read_id($table, 0, { type => "..." })
    my @last_with_rid = $adb->read_id('products', 0, { type => 'last' });
    is( $last_with_rid[0], 6, 'read_id($table, 0, { type => "last" }) returns ID 6' );

    my @first_with_rid = $adb->read_id('products', 0, { type => 'first' });
    is( $first_with_rid[0], 1, 'read_id($table, 0, { type => "first" }) returns ID 1' );

    my @rand_with_rid = $adb->read_id('products', 0, { type => 'rand' });
    ok( $rand_with_rid[0] && $rand_with_rid[0] >= 1 && $rand_with_rid[0] <= 6, 'read_id($table, 0, { type => "rand" }) returns valid record' );

    my $last_with_rid_inf = $adb->read_id('products', 0, { type => 'last', inflate => 1 });
    is( ref($last_with_rid_inf), 'HASH', 'read_id($table, 0, { type => "last", inflate => 1 }) returns HASH' );
    is( $last_with_rid_inf->{id}, 6, 'Inflated last record with dummy rid 0 has ID 6' );

    # Standalone alias methods: read_firstid, read_lastid, read_randid
    my @a_first = $adb->read_firstid('products');
    is( $a_first[0], 1, 'read_firstid alias returns ID 1' );

    my @a_last = $adb->read_lastid('products');
    is( $a_last[0], 6, 'read_lastid alias returns ID 6' );

    my @a_rand = $adb->read_randid('products');
    ok( $a_rand[0] && $a_rand[0] >= 1 && $a_rand[0] <= 6, 'read_randid alias returns valid record' );

    # type with sort (first / last by block name or index, with direction, and standalone read_firstid/read_lastid)
    # Block 'price' (block 4):
    # ID 6: 250 (lowest)
    # ID 5: 400
    # ID 2: 1100
    # ID 1: 1200
    # ID 4: 1800
    # ID 3: 2500 (highest)
    my @first_by_price = $adb->read_id('products', 0, { type => 'first', sort => 'price' });
    is( $first_by_price[0], 6, 'read_id with type => "first", sort => "price" returns lowest price (ID 6)' );

    my @last_by_price = $adb->read_id('products', 0, { type => 'last', sort => 'price' });
    is( $last_by_price[0], 3, 'read_id with type => "last", sort => "price" returns highest price (ID 3)' );

    my @first_by_blk = $adb->read_id('products', 0, { type => 'first', sort => 4 });
    is( $first_by_blk[0], 6, 'read_id with type => "first", sort => 4 (numeric block) returns ID 6' );

    my @last_by_blk = $adb->read_id('products', 0, { type => 'last', sort => 4 });
    is( $last_by_blk[0], 3, 'read_id with type => "last", sort => 4 (numeric block) returns ID 3' );

    my @first_desc = $adb->read_id('products', 0, { type => 'first', sort => { block => 'price', dir => 'desc' } });
    is( $first_desc[0], 3, 'read_id with type => "first", sort desc returns highest price (ID 3)' );

    my @last_desc = $adb->read_id('products', 0, { type => 'last', sort => { block => 'price', dir => 'desc' } });
    is( $last_desc[0], 6, 'read_id with type => "last", sort desc returns lowest price (ID 6)' );

    my @rf_opts = $adb->read_firstid('products', { sort => 'price' });
    is( $rf_opts[0], 6, 'read_firstid with { sort => "price" } returns ID 6' );

    my @rl_opts = $adb->read_lastid('products', { sort => 'price' });
    is( $rl_opts[0], 3, 'read_lastid with { sort => "price" } returns ID 3' );

    my @rf_str = $adb->read_firstid('products', 'price');
    is( $rf_str[0], 6, 'read_firstid with string "price" returns ID 6' );

    my @rl_str = $adb->read_lastid('products', 'price');
    is( $rl_str[0], 3, 'read_lastid with string "price" returns ID 3' );

    my @first_range = $adb->read_id('products', 0, { type => 'first', sort => 'price', range => { block => 'price', min => 1000 } });
    is( $first_range[0], 2, 'read_id with type => "first", sort => "price", range min 1000 returns cheapest >= 1000 (ID 2)' );

    # Test on a table without sort_block (unindexed in-memory fallback)
    $adb->table_create( 'simple_items', { blocks => [ { name => 'id' }, { name => 'val' } ] } );
    $adb->insert_id( 'simple_items', 10, 50 );
    $adb->insert_id( 'simple_items', 20, 10 );
    $adb->insert_id( 'simple_items', 30, 80 );
    my @unindexed_first = $adb->read_id('simple_items', 0, { type => 'first', sort => 'val' });
    is( $unindexed_first[0], 20, 'Unindexed table read_id type => "first", sort => "val" returns ID 20' );
    my @unindexed_last = $adb->read_id('simple_items', 0, { type => 'last', sort => 'val' });
    is( $unindexed_last[0], 30, 'Unindexed table read_id type => "last", sort => "val" returns ID 30' );
};

# ---------------------------------------------------------------------------
subtest '8. field_allfltkeys with standardized \%options and legacy' => sub {
    plan tests => 5;

    # Standardized: single hashref with target_blocks
    my $all1 = $adb->field_allfltkeys('products', {
        target_blocks => [ 2, 3 ]
    });
    is( ref($all1), 'HASH', 'field_allfltkeys returns HASH' );
    is( $all1->{2}{'Smartphones'}, 2, '2 smartphones counted' );
    is( $all1->{3}{'Apple'}, 3, '3 Apple products counted' );

    # Standardized: blocks + base_ids hashref
    my $all2 = $adb->field_allfltkeys('products', [ 2, 3 ], { base_ids => [ 1, 2 ] });
    is( $all2->{2}{'Smartphones'}, 2, 'Scoped field_allfltkeys with hashref base_ids' );

    # Legacy: blocks + base_ids arrayref
    my $all3 = $adb->field_allfltkeys('products', [ 2, 3 ], [ 1, 2 ]);
    is( $all3->{2}{'Smartphones'}, 2, 'Legacy field_allfltkeys with arrayref base_scope' );
};

# ---------------------------------------------------------------------------
subtest '9. facet_menu with standardized single \%options and legacy' => sub {
    plan tests => 6;

    # Standardized: single unified hashref
    my $menu1 = $adb->facet_menu('products', {
        selected => { 2 => 'Smartphones' },
        sort     => 'count'
    });
    ok( $menu1, 'facet_menu with unified hashref generated successfully' );
    is( $menu1->{count}, 2, 'Total matching count is 2' );
    is( scalar(@{ $menu1->{groups} }), 2, '2 facet groups in menu' );

    # Standardized: with offset & limit
    my $menu_paged = $adb->facet_menu('products', {
        offset => 0,
        limit  => 3
    });
    is( scalar(@{ $menu_paged->{ids} }), 3, 'facet_menu with offset/limit paged to 3' );

    # Legacy: 4 arguments
    my $menu_leg = $adb->facet_menu('products', { 2 => 'Smartphones' }, [ 2, 3 ], { sort => 'count' });
    is( $menu_leg->{count}, 2, 'Legacy 4-arg facet_menu matches count' );

    # Legacy: 2 arguments
    my $menu_2arg = $adb->facet_menu('products', { 2 => 'Smartphones' });
    is( $menu_2arg->{count}, 2, 'Legacy 2-arg facet_menu matches count' );
};
