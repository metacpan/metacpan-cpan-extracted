#!/usr/bin/perl

# t/amberdb_read_field_methods.t - Tests for read_field, read_search, read_count, field_keys, field_keyvals

use 5.016000;
use strict;
use warnings;
use Test::More;

use lib 'lib';
use AmberDB;

use File::Temp qw(tempdir);

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
);
isa_ok( $adb, 'AmberDB' );

my $tbl = 'test_methods_' . int( rand(100000) );
$adb->table_attr( $tbl, {
    record_index => 1,
    match_block  => [ 2, 3 ],
    search_block => [ 1, 2 ],
} );

$adb->insert_id( $tbl, 1, 'Inception Christopher Nolan', 'Action', '2010' );
$adb->insert_id( $tbl, 2, 'The Dark Knight', 'Action', '2008' );
$adb->insert_id( $tbl, 3, 'Interstellar', 'SciFi', '2014' );
$adb->insert_id( $tbl, 4, 'Memento', 'Thriller', '2000' );

subtest '1. read_field tests' => sub {
    plan tests => 3;

    # Single value
    my @single = $adb->read_field( $tbl, 2, 'Action' );
    is_deeply( [ sort { $a <=> $b } @single ], [ 1, 2 ], 'read_field single value' );

    # Multiple values via bin_crop OR
    my @multi = $adb->read_field( $tbl, 2, [ 'Action', 'SciFi' ] );
    is_deeply( [ sort { $a <=> $b } @multi ], [ 1, 2, 3 ], 'read_field multi value via bin_crop' );

    # All keys
    my @keys = $adb->read_field( $tbl, 2 );
    is( scalar @keys, 3, 'read_field without values returns 3 distinct keys' );
};

subtest '2. read_search tests' => sub {
    plan tests => 3;

    # Per-block search (Block 1: 'Inception Nolan')
    my @res_b1 = $adb->read_search( $tbl, [ 1 ], 'Inception Nolan' );
    is_deeply( \@res_b1, [ 1 ], 'read_search per-block matches record 1' );

    # Cross-block search ('Inception Action' -> Inception in blk 1, Action in blk 2)
    my @res_cross = $adb->read_search( $tbl, [ 1, 2 ], 'Inception Action', cross_block => 1 );
    is_deeply( \@res_cross, [ 1 ], 'read_search cross-block matches record 1' );

    # Disjoint search
    my @res_none = $adb->read_search( $tbl, [ 1, 2 ], 'NonExistentWord' );
    is_deeply( \@res_none, [], 'read_search returns empty on no match' );
};

subtest '3. field_keys tests (singular & plural)' => sub {
    plan tests => 2;

    my @single_keys = $adb->field_keys( $tbl, 2 );
    is( scalar @single_keys, 3, 'field_keys singular returns 3 keys' );

    my $plural_keys = $adb->field_keys( $tbl, [ 2, 3 ] );
    is( ref($plural_keys), 'HASH', 'field_keys plural returns hashref' );
};

subtest '4. field_keyvals tests' => sub {
    plan tests => 2;

    # All keyvals
    my $all_kv = $adb->field_keyvals( $tbl, 2 );
    is( ref($all_kv), 'HASH', 'field_keyvals without key returns hashref' );

    # Specific key
    my $single_kv = $adb->field_keyvals( $tbl, 2, 'Action' );
    is_deeply( [ sort { $a <=> $b } @{ $single_kv->{'Action'} } ], [ 1, 2 ], 'field_keyvals for Action returns [1, 2]' );
};

subtest '5. read_count tests' => sub {
    plan tests => 2;

    # Test singular (count is 0 since no reads registered in .cnt)
    my $c = $adb->read_count( $tbl, 1 );
    is( $c, 0, 'read_count singular returns 0 for fresh record' );

    # Test plural
    my $counts = $adb->read_count( $tbl, [ 1, 2 ] );
    is_deeply( $counts, { 1 => 0, 2 => 0 }, 'read_count plural returns hashref' );
};

done_testing();
