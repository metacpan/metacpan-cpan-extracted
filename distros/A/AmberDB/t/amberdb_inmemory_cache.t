#!/usr/bin/perl

# t/amberdb_inmemory_cache.t - Tests for in-memory ($self->{_cache}) index, count, lastid, and word caching

use 5.016000;
use strict;
use warnings;
use utf8;
use Test::More;
binmode Test::More->builder->$_, ":utf8" for qw(output failure_output todo_output);
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
use File::Temp qw(tempdir);

use lib 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { language  => 'tr' },
);
isa_ok( $adb, 'AmberDB' );

subtest '1. Word Normalization & get_words In-Memory Caching' => sub {
    plan tests => 9;

    # Normalize word directly
    my $w1 = $adb->normalize_word('İstanbul', 'read');
    is( $w1, 'istanbul', 'normalize_word returns lowercase ascii' );
    ok( exists $adb->{_cache}{nw}{'İstanbul'}, 'normalize_word caches result in $adb->{_cache}{nw}' );

    # Subsequent call hits cache
    my $w2 = $adb->normalize_word('İstanbul', 'read');
    is( $w2, 'istanbul', 'Cached normalize_word matches' );

    # get_words per-word caching
    my %words = $adb->get_words('Bilgisayar ve Kulaklık', 'read');
    ok( exists $adb->{_cache}{gw}{'Bilgisayar'}, 'get_words caches per-word Bilgisayar in $adb->{_cache}{gw}' );
    ok( exists $adb->{_cache}{gw}{'Kulaklık'}, 'get_words caches per-word Kulaklik in $adb->{_cache}{gw}' );

    # minchar caching as empty string
    $adb->get_words('A B Cuma', 'read');
    is( $adb->{_cache}{gw}{'A'}, '', 'Single character A cached as empty string' );
    is( $adb->{_cache}{gw}{'B'}, '', 'Single character B cached as empty string' );

    # stop_word caching as empty string
    my $tbl_sw = 'test_sw_' . int( rand(100000) );
    $adb->table_attr( $tbl_sw, { stop_word => 'ile veya' } );
    $adb->get_words('Elma ile Armut veya Kiraz', 'read', $tbl_sw);
    is( $adb->{_cache}{gw}{'ile'}, '', 'Stop word "ile" cached as empty string' );
    is( $adb->{_cache}{gw}{'veya'}, '', 'Stop word "veya" cached as empty string' );
};

subtest '2. Table .inx Metadata (lastid, count, keys) Caching' => sub {
    plan tests => 8;

    my $tbl = 'test_cache_' . int( rand(100000) );
    $adb->table_attr( $tbl, { record_index => 1, match_block => [2] } );

    $adb->insert_id( $tbl, 10, 'A1', 'V1' );
    $adb->insert_id( $tbl, 20, 'A2', 'V2' );

    # Verify count and lastid
    my $cnt = $adb->table_count($tbl);
    is( $cnt, 2, 'table_count is 2' );
    is( $adb->{_cache}{$tbl}{count}, 2, 'count is cached in $adb->{_cache}{$tbl}{count}' );

    my $last = $adb->table_lastid($tbl);
    is( $last, 20, 'table_lastid is 20' );
    is( $adb->{_cache}{$tbl}{lastid}, 20, 'lastid is cached in $adb->{_cache}{$tbl}{lastid}' );

    # Insert a new record and check cache updates
    $adb->insert_id( $tbl, 30, 'A3', 'V3' );
    is( $adb->table_count($tbl), 3, 'table_count is now 3' );
    is( $adb->{_cache}{$tbl}{count}, 3, 'cached count updated to 3' );
    is( $adb->table_lastid($tbl), 30, 'table_lastid is now 30' );
    is( $adb->{_cache}{$tbl}{lastid}, 30, 'cached lastid updated to 30' );
};

subtest '3. Delete updates cached count and invalidates keys' => sub {
    plan tests => 2;

    my $tbl = 'test_del_cache_' . int( rand(100000) );
    $adb->table_attr( $tbl, { record_index => 1 } );

    $adb->insert_id( $tbl, 1, 'A' );
    $adb->insert_id( $tbl, 2, 'B' );
    $adb->insert_id( $tbl, 3, 'C' );

    is( $adb->table_count($tbl), 3, 'Initial count is 3' );

    $adb->delete_id( $tbl, 2 );
    is( $adb->table_count($tbl), 2, 'Count updated to 2 after deletion' );
};

subtest '4. set_cache and get_cache encapsulation API' => sub {
    plan tests => 8;

    # set_cache and get_cache
    $adb->set_cache( 'test_group', 'my_key', 'hello_world' );
    is( $adb->get_cache( 'test_group', 'my_key' ), 'hello_world', 'get_cache returns set value' );
    is( $adb->{_cache}{test_group}{my_key}, 'hello_world', 'set_cache populates $adb->{_cache}' );

    # multiple keys and group get
    $adb->set_cache( 'test_group', 'k2', 'val2' );
    is( $adb->get_cache( 'test_group', 'k2' ), 'val2', 'get_cache returns val2' );
    my $grp = $adb->get_cache('test_group');
    is( ref($grp), 'HASH', 'get_cache($group) returns group hashref' );
    is( $grp->{k2}, 'val2', 'group hashref contains k2' );

    # set_cache with undef deletes single key
    $adb->set_cache( 'test_group', 'k2', undef );
    ok( !defined $adb->get_cache( 'test_group', 'k2' ), 'set_cache($group, $key, undef) deletes single key' );
    is( $adb->get_cache( 'test_group', 'my_key' ), 'hello_world', 'my_key still exists' );

    # set_cache with only group deletes whole group
    $adb->set_cache('test_group');
    ok( !exists $adb->{_cache}{test_group}, 'set_cache($group) deletes entire group' );
};

subtest '5. Bulk mutations (insert_list, delete_list, table_autoid) invalidate and sync cache' => sub {
    plan tests => 6;

    my $tbl = 'test_bulk_cache_' . int( rand(100000) );
    $adb->table_attr( $tbl, { record_index => 1 } );

    $adb->insert_id( $tbl, 1, 'Initial' );
    is( $adb->table_count($tbl), 1, 'Initial count is 1' );
    is( $adb->get_cache($tbl, 'count'), 1, 'Count is in RAM cache' );

    # insert_list should invalidate table cache
    $adb->insert_list( $tbl, [ 2, 'Item 2' ], [ 3, 'Item 3' ] );
    is( $adb->table_count($tbl), 3, 'Count updated to 3 after insert_list' );

    # delete_list should invalidate table cache
    $adb->delete_list( $tbl, [ 2, 'Item 2' ] );
    is( $adb->table_count($tbl), 2, 'Count updated to 2 after delete_list' );

    # table_autoid syncs RAM cache
    my $new_id = $adb->table_autoid($tbl);
    is( $new_id, 4, 'Auto ID incremented to 4' );
    is( $adb->get_cache($tbl, 'last_autoid'), 4, 'table_autoid synced in-flight autoid directly to RAM cache' );
};

done_testing();
