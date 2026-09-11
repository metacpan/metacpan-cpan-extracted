#!/usr/bin/perl

# t/amberdb_range_filter.t - Tests for range => { block => ..., min => ..., max => ... }
# across read_all, field_fetch, search_table, field_filter, and facet_menu

use 5.016000;
use strict;
use warnings;
use Test::More tests => 7;
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
        { name => 'price' },
    ],
    match_block  => [ 2, 3 ],
    search_block => [ 1 ],
    sort_block   => [ 4 ],
    facet_block  => [ 2, 3 ],
    use_facet    => 1,
} );

# Seed test records: ID, Title, Category, Brand, Price
$adb->insert_id( 'products', 1, 'Apple iPhone 15 Pro Max',  'Smartphones', 'Apple',   1200 );
$adb->insert_id( 'products', 2, 'Samsung Galaxy S24 Ultra', 'Smartphones', 'Samsung', 1100 );
$adb->insert_id( 'products', 3, 'Apple MacBook Pro 16',      'Laptops',     'Apple',   2500 );
$adb->insert_id( 'products', 4, 'Dell XPS 15 Laptop',        'Laptops',     'Dell',    1800 );
$adb->insert_id( 'products', 5, 'Sony WH-1000XM5 Headset',   'Audio',       'Sony',     400 );
$adb->insert_id( 'products', 6, 'Apple AirPods Pro',         'Audio',       'Apple',    250 );

# ---------------------------------------------------------------------------
subtest '1. read_all with range (closed interval, min only, max only, keys_only)' => sub {
    plan tests => 8;

    # 1.1 Closed interval: price 1000 - 2000
    my @p_ids = $adb->read_all( 'products', { range => { block => 4, min => 1000, max => 2000 }, keys_only => 1 } );
    my @expected_ids = sort { $a <=> $b } ( 1, 2, 4 );
    my @got_ids      = sort { $a <=> $b } @p_ids;
    is_deeply( \@got_ids, \@expected_ids, 'read_all with keys_only and range [1000, 2000] returns IDs 1, 2, 4' );

    # 1.2 Closed interval with full records
    my @p_recs = $adb->read_all( 'products', { range => { block => 4, min => 1000, max => 2000 } } );
    is( scalar(@p_recs), 3, 'read_all returns 3 full records' );
    my @rec_ids = sort { $a <=> $b } map { $_->[0] } @p_recs;
    is_deeply( \@rec_ids, \@expected_ids, 'read_all full record IDs match expected' );

    # 1.3 Min only: price >= 1800 (1800, 2500)
    my @min_ids = $adb->read_all( 'products', { range => { block => 4, min => 1800 }, keys_only => 1 } );
    my @got_min = sort { $a <=> $b } @min_ids;
    is_deeply( \@got_min, [ 3, 4 ], 'read_all with min only (>= 1800) returns IDs 3, 4' );

    # 1.4 Max only: min defaults to 0 (price <= 500 -> 250, 400)
    my @max_ids = $adb->read_all( 'products', { range => { block => 4, max => 500 }, keys_only => 1 } );
    my @got_max = sort { $a <=> $b } @max_ids;
    is_deeply( \@got_max, [ 5, 6 ], 'read_all with max only (<= 500) defaults min to 0, returns IDs 5, 6' );

    # 1.5 Named block resolution: block => 'price'
    my @named_ids = $adb->read_all( 'products', { range => { block => 'price', min => 1000, max => 2000 }, keys_only => 1 } );
    my @got_named = sort { $a <=> $b } @named_ids;
    is_deeply( \@got_named, \@expected_ids, 'read_all resolves schema block name "price" correctly' );

    # 1.6 Paginated read_all with range
    my ( $total_cnt, @page_ids ) = $adb->read_all( 'products', { range => { block => 4, min => 1000, max => 2000 }, offset => 0, limit => 2, keys_only => 1 } );
    is( $total_cnt, 3, 'Paginated read_all reports total matching count 3' );
    is( scalar(@page_ids), 2, 'Paginated read_all returns first page of 2 IDs' );
};

# ---------------------------------------------------------------------------
subtest '2. field_fetch with range' => sub {
    plan tests => 3;

    # Fetch Category 'Smartphones' (IDs 1: 1200, 2: 1100) with range price >= 1150
    my @smartphones = $adb->field_fetch( 'products', 2, 'Smartphones', { range => { block => 4, min => 1150 } } );
    is( scalar(@smartphones), 1, 'field_fetch with range filters out records outside range' );
    is( $smartphones[0]->[0], 1, 'Matched record is iPhone 15 Pro Max (ID 1)' );

    # With keys_only => 1
    my @fetch_ids = $adb->field_fetch( 'products', 2, 'Smartphones', { range => { block => 'price', max => 1150 }, keys_only => 1 } );
    is_deeply( \@fetch_ids, [ 2 ], 'field_fetch with keys_only and max => 1150 returns ID 2' );
};

# ---------------------------------------------------------------------------
subtest '3. search_table with range' => sub {
    plan tests => 3;

    # Search for 'Apple' (matches IDs 1: 1200, 3: 2500, 6: 250)
    # Range price 500 - 2000 should only match ID 1 (iPhone 15 Pro Max, 1200)
    my @results = $adb->search_table( 'products', 'Apple', { range => { block => 'price', min => 500, max => 2000 }, keys_only => 1 } );
    is_deeply( \@results, [ 1 ], 'search_table with range [500, 2000] only matches ID 1' );

    # Search for 'Apple' with min => 2000 -> only MacBook (ID 3, 2500)
    my @high_results = $adb->search_table( 'products', 'Apple', { range => { block => 4, min => 2000 }, keys_only => 1 } );
    is_deeply( \@high_results, [ 3 ], 'search_table with min => 2000 only matches ID 3' );

    # Search for 'Apple' with max => 300 -> only AirPods (ID 6, 250)
    my @low_results = $adb->search_table( 'products', 'Apple', { range => { block => 4, max => 300 }, keys_only => 1 } );
    is_deeply( \@low_results, [ 6 ], 'search_table with max => 300 only matches ID 6' );
};

# ---------------------------------------------------------------------------
subtest '4. field_filter with range' => sub {
    plan tests => 2;

    # Filter brand => 'Apple' with price >= 1000 -> IDs 1 (1200) and 3 (2500)
    my $flt_res = $adb->field_filter( 'products', { filter => { 3 => 'Apple' }, range => { block => 4, min => 1000 } } );
    ok( $flt_res && ref($flt_res) eq 'HASH', 'field_filter returns result hash' );
    my @got_flt_ids = sort { $a <=> $b } @{ $flt_res->{ids} || [] };
    is_deeply( \@got_flt_ids, [ 1, 3 ], 'field_filter returns matching IDs [1, 3]' );
};

# ---------------------------------------------------------------------------
subtest '5. facet_menu with range' => sub {
    plan tests => 4;

    # Facet menu with price >= 1000 (only IDs 1, 2, 3, 4 are active)
    my $menu = $adb->facet_menu( 'products', { range => { block => 'price', min => 1000 } } );
    ok( $menu && ref($menu) eq 'HASH', 'facet_menu returns hash result' );

    my @filtered_ids = sort { $a <=> $b } @{ $menu->{ids} || [] };
    is_deeply( \@filtered_ids, [ 1, 2, 3, 4 ], 'facet_menu ids scoped to price >= 1000' );

    # Facet counts for Category (block 2)
    # IDs 1, 2 are Smartphones (count 2), IDs 3, 4 are Laptops (count 2), Audio should be 0
    my $cat_counts = $menu->{counts}->{2} || {};
    is( $cat_counts->{'Smartphones'}, 2, 'Smartphones facet count is 2' );
    is( $cat_counts->{'Audio'} // 0, 0, 'Audio facet count is 0 because outside range' );
};

# ---------------------------------------------------------------------------
subtest '6. field_fltkeys and field_allfltkeys with range' => sub {
    plan tests => 2;

    # Block 2 (category) counts with range price >= 1500 (IDs 3: Laptops 2500, 4: Laptops 1800)
    my $single_flt = $adb->field_fltkeys( 'products', { target_block => 2, range => { block => 4, min => 1500 } } );
    is_deeply( $single_flt, { 'Laptops' => 2 }, 'field_fltkeys respects range filter' );

    # field_allfltkeys with range
    my $all_flt = $adb->field_allfltkeys( 'products', { target_blocks => [ 2 ], range => { block => 4, min => 1500 } } );
    is_deeply( $all_flt->{2}, { 'Laptops' => 2 }, 'field_allfltkeys respects range filter' );
};

# ---------------------------------------------------------------------------
subtest '7. Edge cases (empty results, out-of-range bounds)' => sub {
    plan tests => 2;

    # No items with price > 100,000
    my @empty_res = $adb->read_all( 'products', { range => { block => 4, min => 100000 }, keys_only => 1 } );
    is( scalar(@empty_res), 0, 'Out-of-range min returns empty list' );

    # Non-existent block fails gracefully without crashing
    my @safe_res = $adb->read_all( 'products', { range => { block => 999, min => 10 }, keys_only => 1 } );
    is( scalar(@safe_res), 0, 'Non-existent block returns empty list safely' );
};
