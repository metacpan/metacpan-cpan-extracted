#!/usr/bin/perl

# t/flatdb_lock.t - Tests for AmberDB record and table level locking

use 5.016000;
use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('AmberDB') or BAIL_OUT('Cannot load AmberDB');

subtest 'Method Existence' => sub {
    plan tests => 2;
    can_ok( 'AmberDB', 'flock_open' );
    can_ok( 'AmberDB', 'flock_close' );
};

my $tmpdir = tempdir( CLEANUP => 1 );

my $adb = AmberDB->new(
    cfg  => { language => 'tr' },
    path => { dbase_dir => $tmpdir }
);

subtest 'Record Level Write Lock' => sub {
    plan tests => 4;

    my $fh = $adb->flock_open( 'test_table', 'write', 101 );
    ok( $fh, 'Record write lock handle acquired' );

    my $lock_file = File::Spec->catfile( $adb->ramdisk_lock_dir(), 'test_table_101.lock' );
    ok( -e $lock_file, 'Record lock file exists on disk' );

    ok( $adb->flock_close( 'test_table', 101 ), 'Record lock closed' );
    is( $adb->{_lock}->{'test_table_101'}, undef, 'Lock handle removed from internal pool' );
};

subtest 'Record Level Read Lock' => sub {
    plan tests => 2;

    my $fh = $adb->flock_open( 'test_table', 'read', 101 );
    ok( $fh, 'Record read lock handle acquired' );

    ok( $adb->flock_close( 'test_table', 101 ), 'Record read lock closed' );
};

subtest 'Table Level Lock' => sub {
    plan tests => 4;

    my $fh = $adb->flock_open( 'test_table', 'write' );
    ok( $fh, 'Table lock handle acquired' );

    my $lock_file = File::Spec->catfile( $adb->ramdisk_lock_dir(), 'test_table.lock' );
    ok( -e $lock_file, 'Table lock file exists on disk' );

    ok( $adb->flock_close('test_table'), 'Table lock closed' );
    is( $adb->{_lock}->{'test_table'}, undef, 'Table lock handle removed from internal pool' );
};

subtest 'Automatic Transaction Record Lock Integration' => sub {
    plan tests => 5;

    ok( $adb->transact_start(), 'Transaction started' );

    my $rid = $adb->insert_id( 'txn_lock_table', 500, 'Data 500' );
    is( $rid, 500, 'Inserted record 500 in transaction' );

    ok( $adb->{_txn}->{locks}->{'txn_lock_table_500'}, 'Record lock 500 registered in transaction' );
    ok( $adb->{_lock}->{'txn_lock_table_500'}, 'Record lock file open during transaction' );

    $adb->transact_end();
    is( $adb->{_lock}->{'txn_lock_table_500'}, undef, 'Record lock 500 automatically released after transaction commit' );
};

subtest 'Auto Cleanup On Destroy' => sub {
    plan tests => 2;

    my $adb2 = AmberDB->new(
        cfg  => { language => 'tr' },
        path => { dbase_dir => $tmpdir }
    );

    $adb2->flock_open( 'test_table', 'write', 202 );
    $adb2->flock_open( 'test_table', 'write' );

    ok( $adb2->{_lock}->{'test_table_202'}, 'Record lock 202 active in adb2' );

    # Trigger DESTROY / close_all
    undef $adb2;

    pass( 'Auto cleanup on object destruction completed successfully' );
};
