#!/usr/bin/perl

# t/amberdb_ramdisk_tiers.t - Comprehensive tests for AmberDB RAM-Disk Tiers (0..4)
# Validates canonical string words ('none', 'index', 'dual', 'temp', 'async'),
# Tier 4 write-behind async dirty tracking and coalescing state machine,
# background ramdisk_sync() persistence, and transactional dual-write invariants.

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use lib 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $ram_root = File::Spec->catdir( $tmpdir, 'ramdisk' );
make_path($ram_root);
$ENV{AMBERDB_TEST_RAMDISK} = 1;

# -----------------------------------------------------------------------------
# Subtest 1: Canonical String Normalization & Tier Mapping
# -----------------------------------------------------------------------------
subtest 'Canonical String Normalization' => sub {
    plan tests => 14;

    my $adb = AmberDB->new(
        cfg  => { use_ramdisk => 'dual' },
        path => {
            dbase_dir   => $tmpdir,
            ramdisk_dir => $ram_root,
        }
    );

    # 1. Constructor string normalization
    is( $adb->config('use_ramdisk'), 2, "Constructor 'dual' normalizes to 2" );

    # 2. Config string normalization
    $adb->config( use_ramdisk => 'index' );
    is( $adb->config('use_ramdisk'), 1, "config('index') normalizes to 1" );

    $adb->config( use_ramdisk => 'none' );
    is( $adb->config('use_ramdisk'), 0, "config('none') normalizes to 0" );

    $adb->config( use_ramdisk => 'async' );
    is( $adb->config('use_ramdisk'), 4, "config('async') normalizes to 4" );

    # Global Tier 3 fallback to 0
    $adb->config( use_ramdisk => 'temp' );
    is( $adb->config('use_ramdisk'), 0, "config('temp') falls back to 0 globally" );

    $adb->config( use_ramdisk => 'volatile' );
    is( $adb->config('use_ramdisk'), 0, "config('volatile') falls back to 0 globally" );

    # 3. Table attribute string normalization
    $adb->table_attr( 'tbl_none',  use_ramdisk => 'none' );
    $adb->table_attr( 'tbl_index', use_ramdisk => 'index' );
    $adb->table_attr( 'tbl_dual',  use_ramdisk => 'dual' );
    $adb->table_attr( 'tbl_temp',  use_ramdisk => 'temp' );
    $adb->table_attr( 'tbl_async', use_ramdisk => 'async' );

    is( $adb->table_attr( 'tbl_none',  'use_ramdisk' ), 0, "table_attr('none') normalizes to 0" );
    is( $adb->table_attr( 'tbl_index', 'use_ramdisk' ), 1, "table_attr('index') normalizes to 1" );
    is( $adb->table_attr( 'tbl_dual',  'use_ramdisk' ), 2, "table_attr('dual') normalizes to 2" );
    is( $adb->table_attr( 'tbl_temp',  'use_ramdisk' ), 3, "table_attr('temp') normalizes to 3" );
    is( $adb->table_attr( 'tbl_async', 'use_ramdisk' ), 4, "table_attr('async') normalizes to 4" );

    # Synonyms
    $adb->table_attr( 'tbl_syn1', use_ramdisk => 'mirror' );
    $adb->table_attr( 'tbl_syn2', use_ramdisk => 'ram_only' );
    $adb->table_attr( 'tbl_syn3', use_ramdisk => 'write_behind' );

    is( $adb->table_attr( 'tbl_syn1', 'use_ramdisk' ), 2, "table_attr('mirror') normalizes to 2" );
    is( $adb->table_attr( 'tbl_syn2', 'use_ramdisk' ), 3, "table_attr('ram_only') normalizes to 3" );
    is( $adb->table_attr( 'tbl_syn3', 'use_ramdisk' ), 4, "table_attr('write_behind') normalizes to 4" );
};

# -----------------------------------------------------------------------------
# Subtest 2: Tier 4 Event Tracking & Journal State Machine
# -----------------------------------------------------------------------------
subtest 'Tier 4 Dirty Tracking Journal & State Machine' => sub {
    plan tests => 8;

    my $adb = AmberDB->new(
        cfg  => { language => 'gb' },
        path => {
            dbase_dir   => $tmpdir,
            ramdisk_dir => $ram_root,
        }
    );

    my $dummy_file = "$tmpdir/table/test_events.db";

    # 1. Insert (1) -> Action 'add'
    $adb->ramdisk_mark_dirty( $dummy_file, 101, 1 );
    my @e1 = $adb->journal_read('sync_ramdisk');
    ok( @e1 >= 1, "Journal has entries" );
    is( $e1[-1]->{action}, 'add', "New insert event logged as action 'add'" );
    is( $e1[-1]->{key}, '101', "Key is 101" );

    # 2. Update (2) -> Action 'edit'
    $adb->ramdisk_mark_dirty( $dummy_file, 101, 2 );
    my @e2 = $adb->journal_read('sync_ramdisk');
    is( $e2[-1]->{action}, 'edit', "Update event logged as action 'edit'" );

    # 3. Delete (3) -> Action 'del'
    $adb->ramdisk_mark_dirty( $dummy_file, 101, 3 );
    my @e3 = $adb->journal_read('sync_ramdisk');
    is( $e3[-1]->{action}, 'del', "Delete event logged as action 'del'" );

    # 4. Pos testing: exact numerical offset and raw payload
    $adb->ramdisk_mark_dirty( $dummy_file, 202, 1, 'sample_payload_data', 8000000 );
    my @e4 = $adb->journal_read('sync_ramdisk');
    is( $e4[-1]->{pos}, 8000000, "Exact position recorded in journal entry" );
    is( $e4[-1]->{payload}, 'sample_payload_data', "Raw payload preserved in journal entry" );

    # 5. Unmark dirty is a safe no-op
    ok( $adb->ramdisk_unmark_dirty( $dummy_file, 202 ), "ramdisk_unmark_dirty returns success" );

    # Clean up sync_ramdisk before next subtest
    $adb->journal_delete('sync_ramdisk');
};

# -----------------------------------------------------------------------------
# Subtest 3: Tier 4 Async CRUD and ramdisk_sync()
# -----------------------------------------------------------------------------
subtest 'Tier 4 Async CRUD and Background Sync' => sub {
    plan tests => 14;

    my $adb = AmberDB->new(
        cfg  => { language => 'gb' },
        path => {
            dbase_dir   => $tmpdir,
            ramdisk_dir => $ram_root,
        }
    );

    $adb->table_attr(
        'async_product',
        use_ramdisk  => 'async',
        record_index => 1,
        search_block => [1],
    );

    # 1. Insert record in async mode
    my $id1 = $adb->insert_id( 'async_product', 1, 'Gaming Mouse Ultra', 450 );
    is( $id1, 1, "Record 1 inserted in async mode" );

    # Read from RAM-disk immediately returns fresh data
    my @rec1 = $adb->read_id( 'async_product', 1 );
    is( $rec1[1], 'Gaming Mouse Ultra', "read_id reads record 1 from RAM-disk" );

    # Verify persistent disk file does NOT have the record yet (deferred write)
    my $disk_file = $adb->table_path('async_product') . "." . $adb->{db_ext};
    my $disk_rec  = $adb->recs_get( $disk_file, 1 );
    ok( !$disk_rec->{1}, "Record 1 is NOT yet present on persistent disk (async)" );

    # Verify dirty entry exists in journal sync_ramdisk
    my @events1 = $adb->journal_read('sync_ramdisk');
    ok( ( grep { $_->{key} eq '1' } @events1 ), "Dirty sync event exists for record 1 in journal" );

    # 2. Modify record in async mode
    $adb->modify_id( 'async_product', 1, 'Gaming Mouse RGB Edition', 499 );
    my @rec1_v2 = $adb->read_id( 'async_product', 1 );
    is( $rec1_v2[1], 'Gaming Mouse RGB Edition', "read_id returns updated value from RAM-disk" );

    # 3. Run background sync
    my $synced = $adb->ramdisk_sync('async_product');
    is( $synced, 1, "ramdisk_sync flushed 1 event" );

    # Verify record is now on persistent disk with latest updated value!
    my $disk_rec_synced = $adb->recs_get( $disk_file, 1 );
    ok( $disk_rec_synced->{1}, "Record 1 is now present on persistent disk after sync" );
    my @disk_fields = ( 1, $adb->db_decode( $disk_rec_synced->{1} ) );
    is( $disk_fields[1], 'Gaming Mouse RGB Edition', "Persistent disk contains the latest modified state" );

    # Verify dirty event was cleared from journal after sync
    my @after_sync = $adb->journal_read('sync_ramdisk');
    ok( !( grep { $_->{key} eq '1' } @after_sync ), "Dirty sync event was cleared from journal after sync" );

    # 4. Delete record in async mode
    $adb->delete_id( 'async_product', 1 );
    my @rec1_del = $adb->read_id( 'async_product', 1 );
    ok( !@rec1_del, "Record 1 deleted in RAM-disk" );

    # Persistent disk still has old record until sync runs
    my $disk_del_before = $adb->recs_get( $disk_file, 1 );
    ok( $disk_del_before->{1}, "Disk still has record before sync runs" );

    # Run sync for delete
    my $synced_del = $adb->ramdisk_sync('async_product');
    is( $synced_del, 1, "ramdisk_sync processed delete event" );

    my $disk_del_after = $adb->recs_get( $disk_file, 1 );
    ok( !$disk_del_after->{1}, "Record 1 deleted from persistent disk after sync" );

    my @after_del_sync = $adb->journal_read('sync_ramdisk');
    ok( !( grep { $_->{key} eq '1' } @after_del_sync ), "Delete event cleared from journal after sync" );
};

# -----------------------------------------------------------------------------
# Subtest 4: Transaction Dual-Write Invariant (ACID Guarantee)
# -----------------------------------------------------------------------------
subtest 'Transaction Dual-Write Invariant' => sub {
    plan tests => 11;

    my $adb = AmberDB->new(
        cfg  => { language => 'gb' },
        path => {
            dbase_dir   => $tmpdir,
            ramdisk_dir => $ram_root,
        }
    );

    $adb->table_attr(
        'txn_async_tbl',
        use_ramdisk  => 'async',
        record_index => 1,
    );

    my $disk_file = $adb->table_path('txn_async_tbl') . "." . $adb->{db_ext};
    my $ram_file  = $adb->ramdisk_path('txn_async_tbl') . "." . $adb->{db_ext};

    # --- Transaction Commit Test ---
    $adb->transact_start();
    my $id10 = $adb->insert_id( 'txn_async_tbl', 10, 'Transaction Item', 100 );
    is( $id10, 10, "Record 10 inserted inside transaction" );

    # Inside transaction, dual-write is enforced: MUST be on disk immediately!
    my $disk_r10 = $adb->recs_get( $disk_file, 10 );
    ok( $disk_r10->{10}, "Record 10 written to persistent disk immediately during transaction (dual-write)" );

    my $ram_r10 = $adb->recs_get( $ram_file, 10 );
    ok( $ram_r10->{10}, "Record 10 written to RAM-disk immediately during transaction" );

    # MUST NOT leave a dirty event in sync registry
    my @sh10 = $adb->journal_read('sync_ramdisk');
    ok( !( grep { $_->{key} eq '10' } @sh10 ), "No dirty sync event generated for transacted write" );

    my $end_res = $adb->transact_end();
    is( $end_res->{status}, 'commit', "Transaction committed successfully" );

    # --- Transaction Rollback Test ---
    $adb->transact_start();
    my $id20 = $adb->insert_id( 'txn_async_tbl', 20, 'Rollback Item', 200 );
    is( $id20, 20, "Record 20 inserted inside transaction" );

    # Verify dual-written before rollback
    ok( $adb->recs_get( $disk_file, 20 )->{20}, "Record 20 on disk before rollback" );
    ok( $adb->recs_get( $ram_file, 20 )->{20}, "Record 20 on RAM-disk before rollback" );

    # Trigger rollback
    my $rb_res = $adb->transact_rollback();
    is( $rb_res->{status}, 'rollback', "Transaction rolled back" );

    # Verify rollback purged record from BOTH disk and RAM-disk!
    ok( !$adb->recs_get( $disk_file, 20 )->{20}, "Record 20 reverted from persistent disk" );
    ok( !$adb->recs_get( $ram_file, 20 )->{20}, "Record 20 reverted from RAM-disk" );
};

# -----------------------------------------------------------------------------
# Subtest 5: Tier 4 Bulk Operations (insert_list, delete_list) & Daemon CLI
# -----------------------------------------------------------------------------
subtest 'Tier 4 Bulk Operations and Sync Daemon CLI' => sub {
    plan tests => 10;

    my $adb = AmberDB->new(
        cfg  => { language => 'gb' },
        path => {
            dbase_dir   => $tmpdir,
            ramdisk_dir => $ram_root,
        }
    );

    $adb->table_attr(
        'bulk_async_tbl',
        use_ramdisk  => 'async',
        record_index => 1,
    );

    my $disk_file = $adb->table_path('bulk_async_tbl') . "." . $adb->{db_ext};
    my $ram_file  = $adb->ramdisk_path('bulk_async_tbl') . "." . $adb->{db_ext};
    my $sync_db   = $adb->ramdisk_sync_db_path();

    # 1. Bulk insert in async mode
    my $statu = $adb->insert_list(
        'bulk_async_tbl',
        [ 50, 'Bulk Item 50', 500 ],
        [ 51, 'Bulk Item 51', 510 ],
        [ 52, 'Bulk Item 52', 520 ],
    );
    is( scalar( keys %$statu ), 3, "insert_list inserted 3 records in async mode" );

    # In RAM-disk immediately
    ok( $adb->recs_get( $ram_file, 50 )->{50}, "Record 50 in RAM-disk immediately" );

    # NOT on disk yet
    my $d_rec50_before = -e $disk_file ? $adb->recs_get( $disk_file, 50 ) : undef;
    ok( !$d_rec50_before || !$d_rec50_before->{50}, "Record 50 NOT on persistent disk yet" );

    # Run sync daemon via CLI flush
    my $perl_bin = $^X;
    my $daemon_pl = File::Spec->catfile( 'bin', 'amberdb_daemon.pl' );
    my $cmd = qq{"$perl_bin" -Ilib "$daemon_pl" flush --dbase_dir "$tmpdir" --ramdisk_dir "$ram_root" --verbose};
    my $out = `$cmd`;

    # Verify records now on persistent disk after sync daemon CLI run
    my $d_rec50 = -e $disk_file ? $adb->recs_get( $disk_file, 50 ) : undef;
    my $d_rec51 = -e $disk_file ? $adb->recs_get( $disk_file, 51 ) : undef;
    my $d_rec52 = -e $disk_file ? $adb->recs_get( $disk_file, 52 ) : undef;

    ok( $d_rec50 && $d_rec50->{50}, "Record 50 on persistent disk after daemon sync" );
    ok( $d_rec51 && $d_rec51->{51}, "Record 51 on persistent disk after daemon sync" );
    ok( $d_rec52 && $d_rec52->{52}, "Record 52 on persistent disk after daemon sync" );

    # 2. Bulk delete in async mode
    my $del_statu = $adb->delete_list( 'bulk_async_tbl', 50, 51 );
    is( scalar( keys %$del_statu ), 2, "delete_list deleted 2 records in async mode" );

    # Deleted from RAM-disk immediately
    ok( !$adb->recs_get( $ram_file, 50 )->{50}, "Record 50 deleted from RAM-disk" );

    # Still on persistent disk before daemon sync
    my $d_rec50_del_before = -e $disk_file ? $adb->recs_get( $disk_file, 50 ) : undef;
    ok( $d_rec50_del_before && $d_rec50_del_before->{50}, "Record 50 still on persistent disk before daemon sync" );

    # Run daemon CLI again
    system($cmd);

    # Close handle in test process so DB_File reloads externally modified file
    $adb->table_close($disk_file);

    # Now deleted from persistent disk
    my $d_rec50_del_after = -e $disk_file ? $adb->recs_get( $disk_file, 50 ) : undef;
    ok( !$d_rec50_del_after || !$d_rec50_del_after->{50}, "Record 50 deleted from persistent disk after daemon sync" );
};

done_testing();

