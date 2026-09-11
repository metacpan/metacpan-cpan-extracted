#!/usr/bin/perl

# t/amberdb_cache.t - Tests for AmberDB::Base::Cache (in-memory L1 cache and persistent staging buffer)

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';
use_ok('AmberDB') or BAIL_OUT('Cannot load AmberDB');
use_ok('AmberDB::Base::Cache') or BAIL_OUT('Cannot load AmberDB::Base::Cache');

subtest 'Method Existence' => sub {
    plan tests => 7;
    can_ok( 'AmberDB', 'get_cache' );
    can_ok( 'AmberDB', 'set_cache' );
    can_ok( 'AmberDB', 'clear_cache' );
    can_ok( 'AmberDB', 'buffer_read' );
    can_ok( 'AmberDB', 'buffer_write' );
    can_ok( 'AmberDB', 'buffer_delete' );
    can_ok( 'AmberDB', 'buffer_slot' );
};

my $tmpdir = tempdir( CLEANUP => 1 );

my $adb = AmberDB->new(
    cfg  => { language => 'gb' },
    path => { dbase_dir => $tmpdir }
);

subtest 'In-Memory L1 Cache (set_cache, get_cache, clear_cache)' => sub {
    plan tests => 8;

    # 1. Set and get scalar
    $adb->set_cache( 'products', 'sku_101', 'Widget A' );
    is( $adb->get_cache( 'products', 'sku_101' ), 'Widget A', 'get_cache retrieved scalar value' );

    # 2. Set and get array
    $adb->set_cache( 'products', 'featured', [ 'item1', 'item2' ] );
    my @featured = $adb->get_cache( 'products', 'featured' );
    is_deeply( \@featured, [ 'item1', 'item2' ], 'get_cache returns list in list context' );
    my $featured_ref = $adb->get_cache( 'products', 'featured' );
    is_deeply( $featured_ref, [ 'item1', 'item2' ], 'get_cache returns ref in scalar context' );

    # 3. Get entire group
    my $group = $adb->get_cache('products');
    is( ref($group), 'HASH', 'get_cache without key returns group hash ref' );
    ok( exists $group->{sku_101}, 'group hash contains sku_101' );

    # 4. Clear key
    $adb->clear_cache( 'products', 'sku_101' );
    ok( !defined $adb->get_cache( 'products', 'sku_101' ), 'clear_cache removed specific key' );

    # 5. Clear entire group
    $adb->clear_cache('products');
    ok( !defined $adb->get_cache('products'), 'clear_cache removed entire group' );

    # 6. Global reset
    $adb->set_cache( 'grp1', 'k1', 'v1' );
    $adb->set_cache( 'grp2', 'k2', 'v2' );
    $adb->clear_cache();
    ok( !defined $adb->get_cache('grp1') && !defined $adb->get_cache('grp2'), 'clear_cache() reset all groups' );
};

subtest 'Backward Compatibility Aliases (cache_read, cache_write, cache_delete)' => sub {
    plan tests => 3;

    $adb->cache_write( 'legacy_group', 'legacy_key', 'val1', 'val2' );
    my @ret = $adb->cache_read( 'legacy_group', 'legacy_key' );
    is_deeply( \@ret, [ 'val1', 'val2' ], 'cache_read retrieved value written via cache_write' );

    $adb->cache_delete( 'legacy_group', 'legacy_key' );
    my @after_del = $adb->cache_read( 'legacy_group', 'legacy_key' );
    is( scalar(@after_del), 0, 'cache_delete cleared entry' );

    # Direct check on internal structure
    is( $adb->{_cache}{legacy_group}{legacy_key}, undef, 'Entry absent in internal _cache structure' );
};

subtest 'Persistent Buffer Operations' => sub {
    plan tests => 5;

    # Write to persistent buffer
    my @records = ( [ 1, 'Data 1' ], [ 2, 'Data 2' ] );
    ok( $adb->buffer_write( 'test_table', @records ), 'Buffer write succeeded' );

    # Verify buffer file created in $dbase_dir/buffer/ (not cache/)
    my $buffer_file = File::Spec->catfile( $tmpdir, 'buffer', 'test_table.tmp' );
    ok( -e $buffer_file, 'Buffer file created in persistent buffer/ directory' );

    # Read from buffer
    my @read_buf = $adb->buffer_read('test_table');
    is( scalar(@read_buf), 2, 'Buffer read returned 2 records' );
    is( $read_buf[0]->[1], 'Data 1', 'Buffer record 1 verified' );

    # Delete buffer
    $adb->buffer_delete('test_table');
    ok( !-e $buffer_file, 'Buffer file removed after buffer_delete' );
};

done_testing();
