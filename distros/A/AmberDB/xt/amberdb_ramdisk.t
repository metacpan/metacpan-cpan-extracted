#!/usr/bin/perl

# t/amberdb_ramdisk.t - Comprehensive tests for AmberDB transparent RAM-Disk acceleration layer
# Validates use_ramdisk => 1 (Hybrid/Index-Only), use_ramdisk => 2 (Full Table),
# ramdisk_path symmetry, dual-write synchronization, and transaction rollback.

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
my $ram_mount = tempdir( CLEANUP => 1 );
my $ram_root = File::Spec->catdir( $ram_mount, 'amberdb_testdb' );
make_path($ram_root);
$ENV{AMBERDB_TEST_RAMDISK} = 1;

my $adb = AmberDB->new(
    database => 'testdb',
    cfg  => { language => 'gb' },
    path => {
        dbase_dir   => $tmpdir,
        ramdisk_dir => $ram_root,
    }
);

subtest 'Method Existence & Path Symmetry' => sub {
    plan tests => 10;
    can_ok( 'AmberDB', 'ramdisk_path' );
    can_ok( 'AmberDB', 'ramdisk_ensure' );
    can_ok( 'AmberDB', 'ramdisk_preload' );
    can_ok( 'AmberDB', 'ramdisk_delete' );
    can_ok( 'AmberDB', 'ramdisk_setup' );
    can_ok( 'AmberDB', 'set_shmem' );
    can_ok( 'AmberDB', 'get_shmem' );
    can_ok( 'AmberDB', 'del_shmem' );

    my $t_path = $adb->table_path('sample_tbl');
    my $r_path = $adb->ramdisk_path('sample_tbl');
    ok( $r_path, 'ramdisk_path resolved successfully' );
    like( $r_path, qr/amberdb_testdb[\\\/]table[\\\/]sample_tbl$/, 'ramdisk_path points to amberdb_testdb/table/sample_tbl' );
};

subtest 'use_ramdisk => 1 (Hybrid Index-Only Acceleration)' => sub {
    plan tests => 24;

    $adb->table_attr(
        'hybrid_table',
        use_ramdisk  => 1,
        record_index => 1,
        slug_block   => [1],
        search_block => [2],
        match_block  => [3],
        use_facet    => 1,
        facet_block  => [3],
    );

    # Insert 2 records
    my $id1 = $adb->insert_id( 'hybrid_table', 1, 'Product Alpha', 'ultra fast laptop computer', 'electronics' );
    my $id2 = $adb->insert_id( 'hybrid_table', 2, 'Product Beta',  'slow desktop tower machine', 'electronics' );
    is( $id1, 1, 'Record 1 inserted' );
    is( $id2, 2, 'Record 2 inserted' );

    my $disk_base = $adb->table_path('hybrid_table');
    my $ram_base  = $adb->ramdisk_path('hybrid_table');

    # Verify physical file locations:
    # .db must exist on permanent disk, but NOT on RAM-disk in mode 1
    ok( -e "$disk_base.db",  'Permanent disk has .db' );
    ok( !-e "$ram_base.db",  'RAM-disk does NOT have .db in mode 1 (data remains on disk)' );

    # All indexes must exist on RAM-disk
    ok( -e "$ram_base.inx", 'RAM-disk has .inx' );
    ok( -e "$ram_base.fld", 'RAM-disk has .fld' );
    ok( -e "$ram_base.src", 'RAM-disk has .src' );
    ok( -e "$ram_base.fac", 'RAM-disk has .fac' );
    ok( -e "$ram_base.unq", 'RAM-disk has .unq' );
    ok( -e "$ram_base.slg", 'RAM-disk has .slg' );

    # Durability: Indexes must ALSO be dual-written to permanent disk in mode 1
    ok( -e "$disk_base.inx", 'Permanent disk has .inx (dual-written index)' );
    ok( -e "$disk_base.fld", 'Permanent disk has .fld (dual-written index)' );
    ok( -e "$disk_base.slg", 'Permanent disk has .slg (dual-written index)' );

    # Reading record
    my @rec1 = $adb->read_id( 'hybrid_table', 1 );
    is( $rec1[1], 'Product Alpha', 'read_id correctly reads record from permanent disk' );

    # Slug resolution from RAM-disk
    my $slug_map = $adb->get_slug( 'hybrid_table', 1, 'product-alpha' );
    is( $slug_map->{'product-alpha'}, 1, 'get_slug resolves ID from RAM-disk .slg' );

    # Field fetch and filter via RAM-disk .fld & .unq
    my @ff_recs = $adb->field_fetch( 'hybrid_table', 3, 'electronics' );
    is( scalar(@ff_recs), 2, 'field_fetch finds 2 records via RAM-disk .fld' );

    my $flt_res = $adb->field_filter( 'hybrid_table', { 3 => 'electronics' } );
    is_deeply( [ sort @{ $flt_res->{ids} } ], [ 1, 2 ], 'field_filter resolves records via RAM-disk .unq/.fld' );

    # Search table via RAM-disk .src
    my @src_res = $adb->search_table( 'hybrid_table', 'laptop' );
    is( scalar(@src_res), 1, 'search_table finds 1 record' );
    is( $src_res[0][0], 1, 'search_table found Product Alpha via RAM-disk .src' );

    # Dual-write: update record
    $adb->modify_id( 'hybrid_table', 1, 'Product Alpha Pro', 'ultra fast laptop computer upgraded', 'hardware' );
    my @rec1_mod = $adb->read_id( 'hybrid_table', 1 );
    is( $rec1_mod[1], 'Product Alpha Pro', 'Modified record readable' );

    my $new_slug_map = $adb->get_slug( 'hybrid_table', 1, 'product-alpha-pro' );
    is( $new_slug_map->{'product-alpha-pro'}, 1, 'Updated slug visible in RAM-disk .slg' );

    my @hw_recs = $adb->field_fetch( 'hybrid_table', 3, 'hardware' );
    is( scalar(@hw_recs), 1, 'Updated category found via RAM-disk .fld dual-write' );

    # Dual-write: delete record
    $adb->delete_id( 'hybrid_table', 2 );
    my @rec2_del = $adb->read_id( 'hybrid_table', 2 );
    is( scalar(@rec2_del), 0, 'Record 2 deleted' );

    my @after_del_recs = $adb->field_fetch( 'hybrid_table', 3, 'electronics' );
    is( scalar(@after_del_recs), 0, 'Deleted record purged from RAM-disk .fld dual-write' );
};

subtest 'use_ramdisk => 2 (Full Table Acceleration)' => sub {
    plan tests => 14;

    $adb->table_attr(
        'full_table',
        use_ramdisk  => 2,
        record_index => 1,
        search_block => [2],
    );

    # Insert records
    my $id10 = $adb->insert_id( 'full_table', 10, 'Full Item 10', 'high speed computing' );
    my $id20 = $adb->insert_id( 'full_table', 20, 'Full Item 20', 'low power device' );
    is( $id10, 10, 'Record 10 inserted' );
    is( $id20, 20, 'Record 20 inserted' );

    my $disk_base = $adb->table_path('full_table');
    my $ram_base  = $adb->ramdisk_path('full_table');

    # In mode 2, BOTH disk and RAM-disk must have .db and all indexes
    ok( -e "$disk_base.db",  'Permanent disk has .db' );
    ok( -e "$ram_base.db",   'RAM-disk has .db in mode 2 (full table acceleration)' );
    ok( -e "$ram_base.inx",  'RAM-disk has .inx' );
    ok( -e "$ram_base.src",  'RAM-disk has .src' );

    # Reads directly hit RAM-disk .db
    my @r10 = $adb->read_id( 'full_table', 10 );
    is( $r10[1], 'Full Item 10', 'read_id reads record 10 directly from RAM-disk .db' );

    my @batch = $adb->read_list( 'full_table', [ 10, 20 ] );
    is( scalar(@batch), 2, 'read_list reads in batch from RAM-disk .db' );
    is( $batch[1][1], 'Full Item 20', 'read_list record 20 matches' );

    my @all = $adb->read_all('full_table');
    is( scalar(@all), 2, 'read_all reads all records via RAM-disk .db' );

    # Dual-write: update
    $adb->modify_id( 'full_table', 10, 'Full Item 10 Modified', 'quantum computing' );
    my @r10_mod = $adb->read_id( 'full_table', 10 );
    is( $r10_mod[1], 'Full Item 10 Modified', 'read_id shows modified data from RAM-disk' );

    # Dual-write: delete
    $adb->delete_id( 'full_table', 20 );
    my @r20_del = $adb->read_id( 'full_table', 20 );
    is( scalar(@r20_del), 0, 'Record 20 deleted from RAM-disk' );

    # ramdisk_delete cleans up RAM-disk files
    $adb->ramdisk_delete('full_table');
    ok( !-e "$ram_base.db",  'RAM-disk .db removed by ramdisk_delete' );
    ok( -e "$disk_base.db", 'Permanent disk .db preserved after ramdisk_delete' );
};

subtest 'Transaction Rollback with RAM-Disk' => sub {
    plan tests => 8;

    $adb->table_attr(
        'txn_ram_table',
        use_ramdisk  => 2,
        record_index => 1,
        search_block => [2],
    );

    # Establish baseline record
    $adb->insert_id( 'txn_ram_table', 1, 'Initial Data', 'initial description' );
    my @base_rec = $adb->read_id( 'txn_ram_table', 1 );
    is( $base_rec[1], 'Initial Data', 'Baseline record established' );

    my $disk_base = $adb->table_path('txn_ram_table');
    my $ram_base  = $adb->ramdisk_path('txn_ram_table');

    # Start transaction
    my $txn = $adb->transact_start();
    ok( $txn, 'Transaction started' );

    # Perform insert and modify within transaction
    $adb->insert_id( 'txn_ram_table', 2, 'Txn Record 2', 'temporary description' );
    $adb->modify_id( 'txn_ram_table', 1, 'Modified in Txn', 'modified description' );

    my @in_txn1 = $adb->read_id( 'txn_ram_table', 1 );
    my @in_txn2 = $adb->read_id( 'txn_ram_table', 2 );
    is( $in_txn1[1], 'Modified in Txn', 'Record 1 updated within txn' );
    is( $in_txn2[1], 'Txn Record 2',   'Record 2 created within txn' );

    # Rollback transaction
    my $rb_ok = $adb->transact_rollback($txn);
    ok( $rb_ok, 'Transaction rolled back' );

    # Verify state after rollback in BOTH disk and RAM-disk
    my @after_rb1 = $adb->read_id( 'txn_ram_table', 1 );
    is( $after_rb1[1], 'Initial Data', 'Record 1 restored to Initial Data after rollback' );

    my @after_rb2 = $adb->read_id( 'txn_ram_table', 2 );
    is( scalar(@after_rb2), 0, 'Record 2 undone after rollback' );

    # Verify RAM-disk files are intact and not deleted
    ok( -e "$ram_base.db", 'RAM-disk .db persists and was cleanly restored (not destroyed)' );
};

subtest 'ramdisk_setup helper scripts naming & detection' => sub {
    plan tests => 8;
    my $info = $adb->ramdisk_setup();
    like( $info->{script_pl}, qr/amberdb_cli\.pl$/, 'script_pl points to amberdb_cli.pl' );
    like( $info->{script_bat}, qr/setup_windows\.bat$/, 'script_bat points to setup_windows.bat' );

    # Config registration during AmberDB->new
    is( $adb->config('ramdisk_mounted'), 1, 'config ramdisk_mounted is 1 under test emulation' );
    is( $info->{is_mounted}, 1, 'ramdisk_setup is_mounted is 1' );

    # Test local storage unmounted detection (prevents false positive bug)
    my $t_root = tempdir( CLEANUP => 1 );
    my $plain_ram = File::Spec->catdir( $t_root, 'plain_ram' );
    make_path($plain_ram);
    {
        local $ENV{AMBERDB_TEST_RAMDISK} = 0;
        my $plain_db = AmberDB->new(
            database => 'plain_db',
            path     => { dbase_dir => $t_root, ramdisk_dir => $plain_ram }
        );
        is( $plain_db->config('ramdisk_mounted'), 0, 'Plain local dir config ramdisk_mounted is 0' );
        my $plain_info = $plain_db->ramdisk_setup();
        is( $plain_info->{is_mounted}, 0, 'Plain local directory is correctly identified as unmounted (0)' );
        is( $plain_info->{mount_desc}, 'Local Storage (No RAM-disk active)', 'mount_desc shows local storage' );
    }

    # Test direct RAM-disk path diagnostics
    {
        local $ENV{AMBERDB_TEST_RAMDISK} = 0;
        my $direct_db = AmberDB->new(
            database => 'test',
            path     => { dbase_dir => $t_root, ramdisk_dir => ($^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin') ? 'R:/amberdb_test' : '/dev/shm/amberdb_test' }
        );
        my $d_info = $direct_db->ramdisk_setup();
        ok( defined $d_info->{is_mounted}, 'Direct RAM path diagnostics evaluated' );
    }
};

subtest 'Global use_ramdisk => 1 and 2 configuration' => sub {
    plan tests => 13;

    my $g_tmp = tempdir( CLEANUP => 1 );
    my $g_mount = tempdir( CLEANUP => 1 );
    my $g_ram = File::Spec->catdir( $g_mount, 'amberdb_catalog' );
    make_path($g_ram);

    # 1. First, create database schema and records on permanent disk without RAM-disk
    my $schema_dir = File::Spec->catdir( $g_tmp, 'schema' );
    make_path($schema_dir);

    # Write schema files
    {
        open my $fh1, '>', File::Spec->catfile( $schema_dir, 'catalog_books.table' );
        print $fh1 "{ record_index => 1, search_block => [1] };\n";
        close $fh1;

        open my $fh2, '>', File::Spec->catfile( $schema_dir, 'catalog_authors.table' );
        print $fh2 "{ record_index => 1 };\n";
        close $fh2;

        open my $fh3, '>', File::Spec->catfile( $schema_dir, 'catalog_excluded.table' );
        print $fh3 "{ record_index => 1, use_ramdisk => 0 };\n";
        close $fh3;
    }

    {
        local $ENV{AMBERDB_TEST_RAMDISK} = 0;
        my $init_db = AmberDB->new(
            database => 'catalog',
            path     => { dbase_dir => $g_tmp }
        );

        $init_db->insert_id( 'catalog_books', 1, 'Book One' );
        $init_db->insert_id( 'catalog_authors', 10, 'Author Ten' );
        $init_db->insert_id( 'catalog_excluded', 99, 'Excluded Data' );
    }

    # 2. Open with global cfg => { use_ramdisk => 1 }
    my $adb_g1 = AmberDB->new(
        database => 'catalog',
        cfg  => { use_ramdisk => 1 },
        path => { dbase_dir => $g_tmp, ramdisk_dir => $g_ram }
    );

    # Access catalog_books via table_path
    my $b_path = $adb_g1->table_path('catalog_books');
    my $b_ram  = $adb_g1->ramdisk_path('catalog_books');

    ok( -e "$b_ram.inx", 'Global use_ramdisk => 1 preloads .inx to RAM-disk on table_path' );
    ok( !-e "$b_ram.db", 'Global use_ramdisk => 1 does NOT copy .db (data remains on disk)' );
    is( ($adb_g1->read_id('catalog_books', 1))[1], 'Book One', 'read_id works seamlessly' );

    # Access catalog_authors via table_info
    my $a_info = $adb_g1->table_info('catalog_authors');
    my $a_ram  = $adb_g1->ramdisk_path('catalog_authors');
    is( $a_info->{use_ramdisk}, 1, 'Table inherits global use_ramdisk => 1' );
    ok( -e "$a_ram.inx", 'Preloads .inx on table_info call' );

    # Check excluded table with explicit use_ramdisk => 0
    my $e_info = $adb_g1->table_info('catalog_excluded');
    my $e_ram  = $adb_g1->ramdisk_path('catalog_excluded');
    is( $e_info->{use_ramdisk}, 0, 'Table preserves explicit use_ramdisk => 0 override' );
    ok( !-e "$e_ram.inx", 'Excluded table is NOT copied to RAM-disk' );

    # 3. Open with global cfg => { use_ramdisk => 2 } (Full Table Acceleration)
    my $adb_g2 = AmberDB->new(
        database => 'catalog',
        cfg  => { use_ramdisk => 2 },
        path => { dbase_dir => $g_tmp, ramdisk_dir => $g_ram }
    );

    my $b2_path = $adb_g2->table_path('catalog_books');
    ok( -e "$b_ram.db", 'Global use_ramdisk => 2 preloads .db to RAM-disk on table_path' );
    ok( -e "$b_ram.inx", 'Global use_ramdisk => 2 keeps .inx on RAM-disk' );
    is( ($adb_g2->read_id('catalog_books', 1))[1], 'Book One', 'read_id reads from RAM-disk in mode 2' );

    # Insert new record under global mode 2
    $adb_g2->insert_id( 'catalog_books', 2, 'Book Two' );
    is( ($adb_g2->read_id('catalog_books', 2))[1], 'Book Two', 'Newly inserted record readable' );
    ok( -e "$b_ram.db", 'RAM-disk .db persists with new record' );
    ok( -e "$b_path.db", 'Permanent disk .db dual-written synchronously' );
};

subtest 'Unmounted RAM-disk strips use_ramdisk from table_info and table_attr' => sub {
    plan tests => 6;

    my $u_tmp = tempdir( CLEANUP => 1 );
    my $schema_dir = File::Spec->catdir( $u_tmp, 'schema' );
    make_path($schema_dir);

    {
        open my $fh, '>', File::Spec->catfile( $schema_dir, 'books_rd.table' );
        print $fh "{ record_index => 1, use_ramdisk => 1 };\n";
        close $fh;
    }

    my $u_mount = File::Temp->newdir( CLEANUP => 1 );
    my $u_ram = File::Spec->catdir( $u_mount, 'amberdb_unmount_test' );
    make_path($u_ram);

    # Ensure unmounted state
    local $ENV{AMBERDB_TEST_RAMDISK} = 0;

    my $adb_unmounted = AmberDB->new(
        database => 'unmount_test',
        cfg      => { use_ramdisk => 1 },
        path     => { dbase_dir => $u_tmp, ramdisk_dir => $u_ram }
    );

    # 1. From schema file
    my $file_info = $adb_unmounted->table_info('books_rd');
    ok( !exists $file_info->{use_ramdisk}, 'use_ramdisk stripped from schema file when RAM-disk is unmounted' );

    # 2. From table_attr
    $adb_unmounted->table_attr( 'dynamic_tbl', use_ramdisk => 1 );
    my $attr_info = $adb_unmounted->table_info('dynamic_tbl');
    ok( !exists $attr_info->{use_ramdisk}, 'use_ramdisk stripped from table_info after table_attr when unmounted' );
    is( $adb_unmounted->table_attr( 'dynamic_tbl', 'use_ramdisk' ), undef, 'table_attr getter returns undef when unmounted' );

    # 3. From global config inheritance
    my $glob_info = $adb_unmounted->table_info('unconfigured_tbl');
    ok( !exists $glob_info->{use_ramdisk}, 'Global use_ramdisk is NOT inherited when unmounted' );

    # 4. Now simulate mounted RAM-disk
    local $ENV{AMBERDB_TEST_RAMDISK} = 1;
    my $adb_mounted = AmberDB->new(
        database => 'unmount_test',
        cfg      => { use_ramdisk => 1 },
        path     => { dbase_dir => $u_tmp, ramdisk_dir => $u_ram }
    );

    my $m_file_info = $adb_mounted->table_info('books_rd');
    is( $m_file_info->{use_ramdisk}, 1, 'use_ramdisk preserved when RAM-disk is mounted' );

    $adb_mounted->table_attr( 'dyn_m_tbl', use_ramdisk => 1 );
    is( $adb_mounted->table_attr( 'dyn_m_tbl', 'use_ramdisk' ), 1, 'table_attr preserves use_ramdisk when mounted' );
};

subtest 'use_ramdisk => 3 (Volatile RAM-Disk Tier 3 & TTL)' => sub {
    my $tmp = File::Temp->newdir( CLEANUP => 1 );
    my $t3_mount = File::Temp->newdir( CLEANUP => 1 );
    my $t3_ram = File::Spec->catdir( $t3_mount, 'amberdb_session_db' );
    make_path($t3_ram);
    local $ENV{AMBERDB_TEST_RAMDISK} = 1;

    # 1. Global use_ramdisk => 3 rejection/fallback to 0
    my $adb_global = AmberDB->new(
        database => 'session_db',
        cfg      => { use_ramdisk => 3 },
        path     => { dbase_dir => $tmp, ramdisk_dir => $t3_ram }
    );
    is( $adb_global->config('use_ramdisk'), 0, 'Global use_ramdisk => 3 in constructor falls back to 0' );

    $adb_global->config( use_ramdisk => 3 );
    is( $adb_global->config('use_ramdisk'), 0, 'Global config(use_ramdisk => 3) falls back to 0' );

    my $inh_info = $adb_global->table_info('unspec_table');
    is( $inh_info->{use_ramdisk}, 0, 'Unspecified table inherits 0, not 3' );

    # 2. Per-table use_ramdisk => 3 configuration and schema stripping
    my $adb = AmberDB->new(
        database => 'session_db',
        path     => { dbase_dir => $tmp, ramdisk_dir => $t3_ram }
    );
    my $ramdisk_dir = $adb->ramdisk_dir();

    $adb->table_attr( 'session_store',
        use_ramdisk  => 3,
        search_block => [1],
        record_index => 1,
        match_block  => [2],
    );

    my $s_info = $adb->table_info('session_store');
    is( $s_info->{use_ramdisk}, 3, 'Table configured with use_ramdisk => 3' );
    is( $s_info->{use_simple}, 1, 'Simple mode enforced for Tier 3' );
    is( $s_info->{ramdisk_ttl}, 300, 'Default ramdisk_ttl is 300 seconds' );
    ok( !exists $s_info->{record_index}, 'record_index stripped in Tier 3' );
    ok( !exists $s_info->{search_block}, 'search_block stripped in Tier 3' );
    ok( !exists $s_info->{match_block}, 'match_block stripped in Tier 3' );

    # 3. Write data to Tier 3 volatile table
    ok( $adb->insert_id( 'session_store', 101, 'token_abc', 'user_123' ), 'Record 101 inserted' );
    ok( $adb->insert_id( 'session_store', 102, 'token_xyz', 'user_456' ), 'Record 102 inserted' );

    # Verify physical disk has ZERO files
    my $phys_db = File::Spec->catfile( $tmp, 'table', 'session_store.db' );
    ok( !-e $phys_db, 'Zero physical disk files: table/session_store.db does NOT exist' );
    ok( !-e File::Spec->catfile( $tmp, 'table', 'session_store.inx' ), 'Zero physical disk index files' );

    # Verify RAM-disk contains the .db file
    my $ram_db = File::Spec->catfile( $ramdisk_dir, 'table', 'session_store.db' );
    ok( -e $ram_db, 'RAM-disk contains session_store.db' );
    ok( !-e File::Spec->catfile( $ramdisk_dir, 'table', 'session_store.inx' ), 'RAM-disk has NO index files' );

    # 4. Read records from Tier 3
    my @rec101 = $adb->read_id( 'session_store', 101 );
    is( $rec101[0], 101, 'read_id correctly returns ID 101' );
    is( $rec101[1], 'token_abc', 'read_id correctly returns token_abc' );

    is( $adb->table_count('session_store'), 2, 'table_count is 2' );
    ok( $adb->exist_id( 'session_store', 101 ), 'exist_id is true for 101' );
    ok( !$adb->exist_id( 'session_store', 999 ), 'exist_id is false for nonexistent 999' );

    # 5. Modify record
    ok( $adb->modify_id( 'session_store', 101, 'token_abc_renewed', 'user_123' ), 'modify_id succeeded' );
    my @rec101_mod = $adb->read_id( 'session_store', 101 );
    is( $rec101_mod[1], 'token_abc_renewed', 'Modified token visible in read_id' );

    # 6. Delete record
    ok( $adb->delete_id( 'session_store', 102 ), 'Record 102 deleted' );
    ok( !$adb->exist_id( 'session_store', 102 ), 'Record 102 no longer exists' );
    is( $adb->table_count('session_store'), 1, 'table_count is now 1' );

    # 7. TTL Expiration Simulation
    $adb->table_attr( 'temp_cache', use_ramdisk => 3, ramdisk_ttl => 5 );
    ok( $adb->insert_id( 'temp_cache', 1, 'temp_val' ), 'temp_cache record inserted' );

    my $temp_db = File::Spec->catfile( $ramdisk_dir, 'table', 'temp_cache.db' );
    ok( -e $temp_db, 'temp_cache.db exists in RAM-disk' );

    # Simulate expiration by setting mtime back in time (> 5s ago)
    utime( time() - 20, time() - 20, $temp_db );

    my @exp_rec = $adb->read_id( 'temp_cache', 1 );
    is( scalar @exp_rec, 0, 'read_id returns empty for expired Tier 3 table' );
    ok( !-e $temp_db, 'Expired file was unlinked by _check_ramdisk_ttl' );
    is( $adb->table_count('temp_cache'), 0, 'table_count returns 0 for expired table' );

    # 8. Sliding Expiration
    $adb->table_attr( 'sliding_cache', use_ramdisk => 3, ramdisk_ttl => 60 );
    ok( $adb->insert_id( 'sliding_cache', 1, 'slide_data' ), 'sliding_cache record inserted' );
    my $slide_db = File::Spec->catfile( $ramdisk_dir, 'table', 'sliding_cache.db' );

    # Backdate mtime slightly (25 seconds ago, < 60s TTL)
    utime( time() - 25, time() - 25, $slide_db );
    my $mtime_old = ( stat($slide_db) )[9];

    my @slide_rec = $adb->read_id( 'sliding_cache', 1 );
    is( $slide_rec[1], 'slide_data', 'Unexpired record readable' );
    my $mtime_new = ( stat($slide_db) )[9];
    cmp_ok( $mtime_new, '>', $mtime_old, 'read_id refreshed mtime (sliding expiration)' );
};

subtest 'table_dir custom storage directory (Disk & RAM-Disk)' => sub {
    my $tmp = File::Temp->newdir( CLEANUP => 1 );
    my $tbl_mount = File::Temp->newdir( CLEANUP => 1 );
    my $tbl_ram = File::Spec->catdir( $tbl_mount, 'amberdb_siparis' );
    make_path($tbl_ram);
    local $ENV{AMBERDB_TEST_RAMDISK} = 1;

    my $adb = AmberDB->new(
        database => 'siparis',
        path     => { dbase_dir => $tmp, ramdisk_dir => $tbl_ram }
    );
    my $ramdisk_dir = $adb->ramdisk_dir();

    # 1. Custom table_dir => 'siparis' on physical disk
    $adb->table_attr( 'siparis_tbl', table_dir => 'siparis' );
    my $tpath = $adb->table_path('siparis_tbl');
    like( $tpath, qr{[\\/]siparis[\\/]siparis_tbl$}, 'table_path routed to siparis subfolder' );

    my $rpath = $adb->ramdisk_path('siparis_tbl');
    like( $rpath, qr{[\\/]siparis[\\/]siparis_tbl$}, 'ramdisk_path routed to siparis subfolder' );

    ok( $adb->insert_id( 'siparis_tbl', 10, 'order_detail_10' ), 'Record inserted into siparis_tbl' );
    my $phys_siparis = File::Spec->catfile( $tmp, 'siparis', 'siparis_tbl.db' );
    ok( -e $phys_siparis, 'Physical disk created in dbstore/siparis/siparis_tbl.db' );

    my @order_rec = $adb->read_id( 'siparis_tbl', 10 );
    is( $order_rec[1], 'order_detail_10', 'Record successfully read from siparis directory' );

    # 2. Overwrite default: table_dir => '' stores directly under root dbase_dir
    $adb->table_attr( 'root_tbl', table_dir => '' );
    my $root_tpath = $adb->table_path('root_tbl');
    like( $root_tpath, qr{[\\/]root_tbl$}, 'table_path with table_dir => "" placed directly in root' );
    unlike( $root_tpath, qr{[\\/]tables[\\/]}, 'table_path does not contain tables/' );

    my $root_rpath = $adb->ramdisk_path('root_tbl');
    like( $root_rpath, qr{amberdb_siparis[\\/]root_tbl$}, 'ramdisk_path with table_dir => "" placed directly in amberdb_siparis root' );
    unlike( $root_rpath, qr{[\\/]tables[\\/]}, 'ramdisk_path does not contain tables/' );

    ok( $adb->insert_id( 'root_tbl', 1, 'root_content' ), 'Record inserted into root_tbl' );
    my $phys_root = File::Spec->catfile( $tmp, 'root_tbl.db' );
    ok( -e $phys_root, 'Physical file exists directly at root dbstore/root_tbl.db' );

    # 3. table_dir combined with use_ramdisk => 3 (Tier 3 RAM-disk with custom directory)
    $adb->table_attr( 'volatile_cart',
        use_ramdisk => 3,
        table_dir   => 'cart'
    );
    my $cart_tpath = $adb->table_path('volatile_cart');
    like( $cart_tpath, qr{amberdb_siparis[\\/]cart[\\/]volatile_cart$}, 'table_path points to amberdb_siparis/cart/volatile_cart' );

    ok( $adb->insert_id( 'volatile_cart', 55, 'cart_item_55' ), 'Cart record inserted' );

    my $phys_cart = File::Spec->catfile( $tmp, 'cart', 'volatile_cart.db' );
    ok( !-e $phys_cart, 'Zero physical disk files in dbstore/cart/' );

    my $ram_cart = File::Spec->catfile( $ramdisk_dir, 'cart', 'volatile_cart.db' );
    ok( -e $ram_cart, 'RAM-disk file created in amberdb_siparis/cart/volatile_cart.db' );

    my @cart_rec = $adb->read_id( 'volatile_cart', 55 );
    is( $cart_rec[1], 'cart_item_55', 'Cart record read from custom RAM-disk directory' );

    # 4. Schema dump preserves table_dir in table_infset
    $adb->table_infset('siparis_tbl');
    my $schema_file = File::Spec->catfile( $tmp, 'schema', 'siparis_tbl.table' );
    ok( -e $schema_file, 'schema file created by table_infset' );
    my $schema_content = do { local $/; open my $fh, '<', $schema_file; <$fh> };
    like( $schema_content, qr{table_dir\s*=>\s*"siparis"}, 'table_infset persists table_dir => "siparis"' );
};

subtest 'Shared Memory (shmem) Store & Zero-Fallback Validation' => sub {
    plan tests => 28;

    # 1. Scalar, Hash, Array storage in active RAM-disk
    ok( $adb->set_shmem( 'test_scalar', 'hello_world' ), 'set_shmem stored scalar' );
    is( $adb->get_shmem('test_scalar'), 'hello_world', 'get_shmem retrieved scalar' );

    my $hash_data = { user => 'maruf', roles => [ 'admin', 'dev' ], active => 1 };
    ok( $adb->set_shmem( 'user_profile', $hash_data ), 'set_shmem stored complex hash ref' );
    is_deeply( $adb->get_shmem('user_profile'), $hash_data, 'get_shmem retrieved complex hash ref accurately' );

    my $arr_data = [ 100, 200, 300, { nested => 'ok' } ];
    ok( $adb->set_shmem( 'config_items', $arr_data ), 'set_shmem stored array ref' );
    is_deeply( $adb->get_shmem('config_items'), $arr_data, 'get_shmem retrieved array ref accurately' );

    # Verify physical file existence in $ramdisk_dir/shmem/
    my $shm_path = File::Spec->catfile( $adb->path('shmem_dir'), 'test_scalar.shm' );
    ok( -e $shm_path, 'Physical .shm file exists in shmem/' );

    # 2. Deletion
    ok( $adb->del_shmem('test_scalar'), 'del_shmem removed test_scalar' );
    is( $adb->get_shmem('test_scalar'), undef, 'get_shmem returns undef for deleted key' );
    ok( !-e $shm_path, 'Physical .shm file removed by del_shmem' );

    # 3. TTL Expiration
    ok( $adb->set_shmem( 'ttl_key', 'short_lived', 1 ), 'set_shmem stored key with 1s TTL' );
    is( $adb->get_shmem('ttl_key'), 'short_lived', 'get_shmem immediately returns unexpired key' );
    sleep 2;
    is( $adb->get_shmem('ttl_key'), undef, 'get_shmem returns undef after TTL expiry' );
    my $ttl_file = File::Spec->catfile( $adb->path('shmem_dir'), 'ttl_key.shm' );
    ok( !-e $ttl_file, 'Expired file was unlinked by get_shmem' );

    # 4. Zero-Fallback & Database Name Validation (No RAM-disk active)
    my $plain_tmp = tempdir( CLEANUP => 1 );
    {
        local $ENV{AMBERDB_TEST_RAMDISK} = 0;
        my $plain_db = AmberDB->new(
            database => '', # Empty dbname -> must NOT mount RAM-disk
            path     => { dbase_dir => $plain_tmp }
        );
        is( $plain_db->config('ramdisk_mounted'), 0, 'Unmounted AmberDB has ramdisk_mounted => 0' );
        is( $plain_db->set_shmem( 'forbidden_key', 'should_not_save' ), undef, 'set_shmem returns undef when unmounted' );
        is( $plain_db->get_shmem('forbidden_key'), undef, 'get_shmem returns undef when unmounted' );

        # Verify zero-fallback: ramdisk_dir and all *_rdir paths are empty string
        is( $plain_db->ramdisk_dir(), '', 'ramdisk_dir is empty string when unmounted' );
        is( $plain_db->path('ramdisk_dir'), '', 'path ramdisk_dir is empty string when unmounted' );
        is( $plain_db->path('table_rdir'), '', 'path table_rdir is empty string when unmounted' );
        is( $plain_db->path('schema_rdir'), '', 'path schema_rdir is empty string when unmounted' );
        is( $plain_db->path('config_rdir'), '', 'path config_rdir is empty string when unmounted' );
        is( $plain_db->ramdisk_tbl_dir(), '', 'ramdisk_tbl_dir() returns empty string when unmounted' );
        is( $plain_db->ramdisk_schema_dir(), '', 'ramdisk_schema_dir() returns empty string when unmounted' );
        is( $plain_db->ramdisk_path('sample_tbl'), '', 'ramdisk_path returns empty string when unmounted' );
        ok( !exists $plain_db->{_path}->{shmem_dir}, 'shmem_dir key deleted from _path when unmounted' );

        # Verify zero disk files or fake ramdisk directory created on disk
        my $unwanted_shm = File::Spec->catdir( $plain_tmp, 'shmem' );
        ok( !-d $unwanted_shm, 'Zero-fallback: No shmem directory created on disk when unmounted' );
        my $fake_ramdisk = File::Spec->catdir( $plain_tmp, 'ramdisk' );
        ok( !-d $fake_ramdisk, 'Zero-fallback: No fake dbase_dir/ramdisk directory created on disk' );
    }
};

done_testing();
