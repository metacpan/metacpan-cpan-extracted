#!/usr/bin/perl

# t/amberdb/amberdb_transact.t - Tests for AmberDB Transaction functionality

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
use AmberDB::Base::Transact;
use AmberDB::Base::Index;

# ---------------------------------------------------------------------------
subtest 'Transact Methods Existence' => sub {
    plan tests => 7;
    can_ok( 'AmberDB', 'transact_start' );
    can_ok( 'AmberDB', 'transact_end' );
    can_ok( 'AmberDB', 'transact_rollback' );
    can_ok( 'AmberDB', 'transact_recover' );
    can_ok( 'AmberDB', 'transact_recover' );
    can_ok( 'AmberDB', 'transact_error' );
    can_ok( 'AmberDB::Base::Transact', 'transact_start' );
};

# Setup temporary database directory for testing
my $tmpdir = tempdir( CLEANUP => 1 );

my $adb = AmberDB->new(
    cfg  => { language => 'tr' },
    path => { dbase_dir => $tmpdir }
);

# ---------------------------------------------------------------------------
subtest 'Successful Transaction (Commit)' => sub {
    plan tests => 5;

    ok( $adb->transact_start(), 'Transaction started' );

    my $rid1 = $adb->insert_id( 'test_table', 1, 'Item 1', 'Category A', 100 );
    is( $rid1, 1, 'Inserted record 1' );

    my $rid2 = $adb->insert_id( 'test_table', 2, 'Item 2', 'Category B', 200 );
    is( $rid2, 2, 'Inserted record 2' );

    my $res = $adb->transact_end();
    is( $res->{status}, 'commit', 'Transaction committed' );

    my @rec1 = $adb->read_id( 'test_table', 1 );
    is( $rec1[1], 'Item 1', 'Record 1 persisted in database' );
};

# ---------------------------------------------------------------------------
subtest 'Base Error Triggers Rollback' => sub {
    plan tests => 5;

    ok( $adb->transact_start(), 'Transaction started' );

    # Successful insert
    $adb->insert_id( 'test_table', 10, 'Item 10', 'Category A', 500 );

    # Duplicate ID insert -> triggers base error in insert_id
    my $dup_rid = $adb->insert_id( 'test_table', 10, 'Item 10 Dup', 'Category A', 500 );
    is( $dup_rid, undef, 'Duplicate ID failed as expected' );

    my $res = $adb->transact_end();
    is( $res->{status}, 'rollback', 'Transaction rolled back automatically' );

    my @rec10 = $adb->read_id( 'test_table', 10 );
    is( scalar(@rec10), 0, 'Record 10 rolled back and deleted from .db' );

    my @all_keys = $adb->table_keys('test_table');
    ok( !grep( { $_ eq '10' } @all_keys ), 'Record 10 removed from index (.inx)' );
};

# ---------------------------------------------------------------------------
subtest 'Manual Rollback' => sub {
    plan tests => 4;

    ok( $adb->transact_start(), 'Transaction started' );

    $adb->insert_id( 'test_table', 20, 'Item 20', 'Category C', 300 );
    $adb->modify_id( 'test_table', 20, 'Item 20 Updated', 'Category C', 350 );

    my $res = $adb->transact_rollback();
    is( $res->{status}, 'rollback', 'Manual rollback executed' );

    my @rec20 = $adb->read_id( 'test_table', 20 );
    is( scalar(@rec20), 0, 'Record 20 completely removed after manual rollback' );

    my @all_keys = $adb->table_keys('test_table');
    ok( !grep( { $_ eq '20' } @all_keys ), 'Record 20 absent from index' );
};

# ---------------------------------------------------------------------------
subtest 'Rollback of Delete Operation (with keep_deleted .del archive cleanup)' => sub {
    plan tests => 6;

    # Configure table with keep_deleted => 1
    $adb->table_attr( 'test_table', keep_deleted => 1 );

    # Insert initial record outside of failing transaction
    $adb->insert_id( 'test_table', 30, 'Item 30 Pre', 'Category D', 400 );
    my @pre30 = $adb->read_id( 'test_table', 30 );
    is( $pre30[1], 'Item 30 Pre', 'Initial record 30 created' );

    $adb->transact_start();

    # Delete record 30 (moves to .del archive because keep_deleted is 1)
    $adb->delete_id( 'test_table', 30 );

    # Verify record was moved to .del archive during active transaction
    my $del_path = $adb->table_path('test_table') . ".del";
    $adb->table_read($del_path);
    my $del_res = $adb->recs_get( $del_path, 30 );
    $adb->table_close($del_path);
    ok( $del_res && $del_res->{30}, 'Record 30 is present in .del archive during transaction' );

    # Trigger a base error (modify non-existent record 9999)
    $adb->modify_id( 'test_table', 9999, 'Non-existent' );

    my $res = $adb->transact_end();
    is( $res->{status}, 'rollback', 'Transaction rolled back' );

    my @rec30 = $adb->read_id( 'test_table', 30 );
    is( $rec30[1], 'Item 30 Pre', 'Deleted record 30 restored to active table after rollback' );

    my @all_keys = $adb->table_keys('test_table');
    ok( grep( { $_ eq '30' } @all_keys ), 'Record 30 restored in index (.inx)' );

    # Verify record 30 is cleaned up and removed from .del archive after rollback
    $adb->table_read($del_path);
    my $del_after = $adb->recs_get( $del_path, 30 );
    $adb->table_close($del_path);
    ok( !$del_after || !$del_after->{30}, 'Record 30 cleanly removed from .del archive after rollback' );
};

# ---------------------------------------------------------------------------
subtest 'Rollback of log_owner Audit Log (.aut)' => sub {
    plan tests => 5;

    # Configure table with record_index => 1 and log_owner => 1
    $adb->table_attr( 'test_table', record_index => 1, log_owner => 1 );

    # 1. Insert record outside transaction
    $adb->insert_id( 'test_table', 50, 'Item 50 Base', 'Category Z', 100 );
    my $aut_path = $adb->table_path('test_table') . ".aut";
    $adb->table_read($aut_path);
    my $res_base = $adb->recs_get( $aut_path, 50 );
    $adb->table_close($aut_path);
    ok( $res_base && $res_base->{50}, 'Auth entry created for record 50' );

    # 2. Start transaction, modify record 50, then trigger rollback
    $adb->transact_start();
    $adb->modify_id( 'test_table', 50, 'Item 50 Mod', 'Category Z', 150 );

    # Trigger error
    $adb->modify_id( 'test_table', 9999, 'Non-existent' );
    my $res = $adb->transact_end();
    is( $res->{status}, 'rollback', 'Transaction rolled back' );

    # Verify record 50 value was restored
    my @rec50 = $adb->read_id( 'test_table', 50 );
    is( $rec50[1], 'Item 50 Base', 'Record 50 data restored' );

    # 3. Start transaction, insert record 51, then trigger rollback
    $adb->transact_start();
    $adb->insert_id( 'test_table', 51, 'Item 51 Temp', 'Category Z', 200 );
    $adb->transact_rollback();

    my @rec51 = $adb->read_id( 'test_table', 51 );
    is( scalar(@rec51), 0, 'Record 51 rolled back' );

    $adb->table_read($aut_path);
    my $res_aut = $adb->recs_get( $aut_path, 51 );
    $adb->table_close($aut_path);
    ok( !$res_aut || !$res_aut->{51}, 'Record 51 audit entry completely removed from .aut after rollback' );
};

# ---------------------------------------------------------------------------
subtest 'Index Error Does NOT Trigger Rollback' => sub {
    plan tests => 3;

    ok( $adb->transact_start(), 'Transaction started' );

    # Manually register an index-classified error
    $adb->transact_error( 'test_table.inx', 'Simulated non-critical index write failure' );

    # Perform valid base insert with monotonic ID 60
    $adb->insert_id( 'test_table', 60, 'Item 60', 'Category E', 600 );

    my $res = $adb->transact_end();
    is( $res->{status}, 'commit', 'Transaction committed despite index error' );

    my @rec60 = $adb->read_id( 'test_table', 60 );
    is( $rec60[1], 'Item 60', 'Base record 60 successfully persisted' );
};

# ---------------------------------------------------------------------------
subtest 'Orphan Transaction Recovery & Lock Protection' => sub {
    plan tests => 5;

    my $journal_dir = $adb->journal_dir();

    # 1. Test dead orphan recovery (simulate process crash by abandoning transaction)
    $adb->transact_start();
    $adb->insert_id( 'test_table', 65, 'Item 65 Orphan', 'Category O', 650 );
    my $orphan_file = $adb->{_txn}->{file};
    close( delete $adb->{_txn}->{fh} );
    delete $adb->{_txn};
    $adb->close_all();

    ok( -e $orphan_file, 'Orphan journal file created for test' );

    # Call recover orphans
    $adb->transact_recover();

    ok( !-e $orphan_file, 'Orphan journal file removed after recovery' );

    my @rec65 = $adb->read_id( 'test_table', 65 );
    is( scalar(@rec65), 0, 'Orphaned insert was rolled back' );

    # 2. Test active locked journal protection
    my $locked_file = File::Spec->catfile( $journal_dir, 'txn_locked_test_888888' );
    open my $lfh, '+>>', $locked_file or die "Cannot create locked test file: $!";
    use Fcntl qw(:flock);
    flock( $lfh, LOCK_EX ); # Actively lock file

    $adb->transact_recover();
    ok( -e $locked_file, 'Actively locked journal file is NOT removed by orphan recovery' );

    flock( $lfh, LOCK_UN );
    close $lfh;
    unlink $locked_file;
    ok( !-e $locked_file, 'Locked test file cleaned up' );
};

# ---------------------------------------------------------------------------
subtest 'Transaction Durability with txn_sync' => sub {
    plan tests => 4;

    my $sync_adb = AmberDB->new(
        cfg  => { language => 'tr', txn_sync => 1 },
        path => { dbase_dir => $tmpdir }
    );

    ok( $sync_adb->transact_start(), 'Transaction started with txn_sync enabled' );
    my $rid70 = $sync_adb->insert_id( 'test_table', 70, 'Item 70 Sync', 'Category S', 750 );
    is( $rid70, 70, 'Inserted record 70 with sync enabled' );

    my $res = $sync_adb->transact_end();
    is( $res->{status}, 'commit', 'Transaction committed with fsync' );

    my @rec70 = $sync_adb->read_id( 'test_table', 70 );
    is( $rec70[1], 'Item 70 Sync', 'Synced record 70 read back successfully' );
};

# ---------------------------------------------------------------------------
subtest 'no_transact Tables Do NOT Trigger Rollback on Failure' => sub {
    plan tests => 6;

    # 1. Configure auxiliary table with no_transact => 1 via table_attr
    $adb->table_attr( 'aux_log_table', no_transact => 1 );
    is( $adb->table_attr( 'aux_log_table', 'no_transact' ), 1, 'aux_log_table configured with no_transact => 1' );

    ok( $adb->transact_start(), 'Transaction started' );

    # Primary operation: insert critical order in test_table
    $adb->insert_id( 'test_table', 80, 'Critical Order 80', 'Sales', 1500 );

    # Auxiliary operation: simulate an error on no_transact table (modify non-existent id)
    $adb->modify_id( 'aux_log_table', 99999, 'Failed Auxiliary Update' );

    # Transaction commit should succeed because aux_log_table has no_transact => 1
    my $res = $adb->transact_end();
    is( $res->{status}, 'commit', 'Transaction committed successfully despite error on no_transact table' );

    my @rec80 = $adb->read_id( 'test_table', 80 );
    is( $rec80[1], 'Critical Order 80', 'Primary critical record 80 persisted cleanly' );

    # 2. Test rollback consistency: if primary fails, auxiliary operations are still rolled back
    ok( $adb->transact_start(), 'Second transaction started' );
    $adb->insert_id( 'aux_log_table', 101, 'Aux Event 101' );
    $adb->modify_id( 'test_table', 99999, 'Non-existent critical error' ); # Triggers rollback

    my $res2 = $adb->transact_end();
    is( $res2->{status}, 'rollback', 'Transaction with primary failure rolled back' );
};

done_testing();

