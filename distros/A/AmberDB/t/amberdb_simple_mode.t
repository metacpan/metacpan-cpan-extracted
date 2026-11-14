use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';

use AmberDB;
use AmberDB::Tools;

my $tmp_dir = tempdir( CLEANUP => 1 );
my $tools   = AmberDB::Tools->new();

# ============================================================
# 1. Initialization and ID Flexibility in Simple Mode
# ============================================================
subtest '1. Simple Mode ID Flexibility (No 8-byte or Numeric Limit)' => sub {
    my $db_dir = "$tmp_dir/simple_db1";
    mkdir($db_dir);

    my $adb = $tools->db_simple($db_dir);
    isa_ok( $adb, 'AmberDB' );
    is( $adb->config('simple'), 1, 'Simple mode is active in config' );

    # Arbitrary ID formats that would exceed 8-bytes or contain non-digits
    my @test_ids = (
        'user@example.com',                                  # Email format (special chars @ and .)
        'sess_99999_abcdef_1234567890_extra_long_token',     # Long ASCII token (> 8 bytes)
        'TR-2026-08-23-INVOICE-001',                         # Hyphenated uppercase string (> 8 bytes)
        '100500',                                            # Standard numeric ID
        'prod_özellik_kırmızı_xl',                           # Turkish chars in key
    );

    foreach my $id (@test_ids) {
        my $inserted = $adb->insert_id( 'sessions', $id, 'Active', 'Chrome', time() );
        is( $inserted, $id, "insert_id succeeded with arbitrary ID: $id" );

        my @read = $adb->read_id( 'sessions', $id );
        is( $read[0], $id, "read_id returned exact ID: $id" );
        is( $read[1], 'Active', "read_id field 1 matches for $id" );

        my $exists = $adb->exist_id( 'sessions', $id );
        is( $exists, 1, "exist_id confirms key exists: $id" );
    }

    # Verify that ONLY sessions.db was created, NO index files (.inx, .fld, .src, .srt, .fac, .slg)
    my @created_files = glob("$db_dir/*");
    my @index_files   = grep { /\.(inx|fld|src|srt|fac|slg)$/ } @created_files;
    is_deeply( \@index_files, [], 'No index files (.inx, .fld, .src, .srt, .fac, .slg) generated' );
};

# ============================================================
# 2. CRUD Operations with Arbitrary IDs
# ============================================================
subtest '2. CRUD Lifecycle & Bulk Operations in Simple Mode' => sub {
    my $db_dir = "$tmp_dir/simple_db2";
    mkdir($db_dir);
    my $adb = $tools->db_simple($db_dir);

    # Single Modify
    my $id1 = 'custom_order_uuid_123456789';
    $adb->insert_id( 'orders', $id1, 'Pending', '150.00' );
    my $mod_res = $adb->modify_id( 'orders', $id1, 'Completed', '175.50' );
    ok( $mod_res, "modify_id succeeded on string ID: $id1" );

    my @read = $adb->read_id( 'orders', $id1 );
    is( $read[1], 'Completed', 'Status updated to Completed' );
    is( $read[2], '175.50',    'Amount updated to 175.50' );

    # Single Delete
    my $del_res = $adb->delete_id( 'orders', $id1 );
    ok( $del_res, "delete_id succeeded on string ID: $id1" );
    my @read_del = $adb->read_id( 'orders', $id1 );
    ok( !@read_del, 'Deleted record not returned by read_id' );

    # Bulk Insert (insert_list)
    my @bulk_data = (
        [ 'bulk_id_alpha_01', 'Item Alpha', 'Cat A', '50.00' ],
        [ 'bulk_id_beta_02',  'Item Beta',  'Cat B', '75.00' ],
        [ 'bulk_id_gamma_03', 'Item Gamma', 'Cat A', '120.00' ],
    );
    my $bulk_status = $adb->insert_list( 'orders', @bulk_data );
    is( scalar( keys %$bulk_status ), 3, 'insert_list inserted 3 arbitrary string ID records' );

    # Bulk Modify (modify_list)
    my @bulk_mod = (
        [ 'bulk_id_alpha_01', 'Item Alpha Updated', 'Cat A', '55.00' ],
        [ 'bulk_id_beta_02',  'Item Beta Updated',  'Cat B', '80.00' ],
    );
    my $mod_status = $adb->modify_list( 'orders', @bulk_mod );
    is( scalar( keys %$mod_status ), 2, 'modify_list updated 2 records' );
    my @read_alpha = $adb->read_id( 'orders', 'bulk_id_alpha_01' );
    is( $read_alpha[1], 'Item Alpha Updated', 'Bulk modified value persisted' );

    # Bulk Delete (delete_list)
    my $del_status = $adb->delete_list( 'orders', 'bulk_id_alpha_01', 'bulk_id_beta_02' );
    is( scalar( keys %$del_status ), 2, 'delete_list deleted 2 records' );
    my $left_count = $adb->table_count('orders');
    is( $left_count, 1, 'Only 1 record remaining in table' );
};

# ============================================================
# 3. read_all in Simple Mode (Full Table Scan & Options)
# ============================================================
subtest '3. read_all in Simple Mode' => sub {
    my $db_dir = "$tmp_dir/simple_db3";
    mkdir($db_dir);
    my $adb = $tools->db_simple($db_dir);

    # Insert test dataset with varying prices: Block 1: Name, Block 2: Category, Block 3: Price
    $adb->insert_id( 'items', 'item_101', 'Laptop',     'Elektronik', '1500' );
    $adb->insert_id( 'items', 'item_102', 'Mouse',      'Elektronik', '25' );
    $adb->insert_id( 'items', 'item_103', 'Klavye',     'Elektronik', '75' );
    $adb->insert_id( 'items', 'item_104', 'Monitör',    'Elektronik', '300' );
    $adb->insert_id( 'items', 'item_105', 'Kulaklık',   'Elektronik', '50' );

    # 1. read_all all records
    my @all = $adb->read_all('items');
    is( scalar(@all), 5, 'read_all returns all 5 records without schema/index' );

    # 2. keys_only => 1
    my @keys = $adb->read_all( 'items', keys_only => 1 );
    is( scalar(@keys), 5, 'keys_only returns 5 keys' );
    ok( !ref( $keys[0] ), 'keys_only returns scalar IDs' );

    # 3. Pagination (start => 1, limit => 2)
    my ( $count, @paged ) = $adb->read_all( 'items', 1, 2 );
    is( $count, 5, 'Pagination total count is 5' );
    is( scalar(@paged), 2, 'Paged slice returns 2 items' );

    # 4. In-Memory Sorting (sort => 3 - price DESC)
    my @sorted_desc = $adb->read_all( 'items', sort => 3, keys_only => 1 );
    is( $sorted_desc[0], 'item_101', 'Price DESC highest first is item_101 (1500)' );

    # 5. In-Memory Sorting (sort => -3 - price ASC)
    my @sorted_asc = $adb->read_all( 'items', sort => -3, keys_only => 1 );
    is( $sorted_asc[0], 'item_102', 'Price ASC lowest first is item_102 (25)' );
};

# ============================================================
# 4. field_fetch in Simple Mode (Unindexed Direct Scan)
# ============================================================
subtest '4. field_fetch in Simple Mode' => sub {
    my $db_dir = "$tmp_dir/simple_db4";
    mkdir($db_dir);
    my $adb = $tools->db_simple($db_dir);

    # Block 1: Name, Block 2: Category, Block 3: Color, Block 4: Price
    $adb->insert_id( 'catalog', 'c_01', 'T-Shirt', 'Giyim',     'Mavi',    '100' );
    $adb->insert_id( 'catalog', 'c_02', 'Pantolon', 'Giyim',     'Siyah',   '250' );
    $adb->insert_id( 'catalog', 'c_03', 'Gömlek',   'Giyim',     'Mavi',    '180' );
    $adb->insert_id( 'catalog', 'c_04', 'Telefon',  'Teknoloji', 'Siyah',   '5000' );
    $adb->insert_id( 'catalog', 'c_05', 'Kemer',    'Aksesuar',  'Kahve',   '80' );

    # 1. Simple field_fetch (Block 2: Category = Giyim)
    my @giyim = $adb->field_fetch( 'catalog', 2, 'Giyim' );
    is( scalar(@giyim), 3, 'field_fetch Category=Giyim matched 3 records' );

    # 2. Multi-value fetch (Block 3: Color in ['Mavi', 'Kahve'])
    my @colors = $adb->field_fetch( 'catalog', 3, [ 'Mavi', 'Kahve' ] );
    is( scalar(@colors), 3, 'field_fetch multi-value Color in [Mavi, Kahve] matched 3 records' );

    # 3. keys_only option
    my @giyim_keys = $adb->field_fetch( 'catalog', 2, 'Giyim', keys_only => 1 );
    is( scalar(@giyim_keys), 3, 'keys_only returns 3 scalar IDs' );
    ok( !ref( $giyim_keys[0] ), 'Element is scalar string ID' );

    # 4. Pagination and Sorting with field_fetch (Block 4: Price ASC sort => -4)
    my ( $cnt, @giyim_sorted ) = $adb->field_fetch( 'catalog', 2, 'Giyim', 0, 2, sort => -4 );
    is( $cnt, 3, 'field_fetch total count before limit is 3' );
    is( scalar(@giyim_sorted), 2, 'field_fetch limit 2 returned 2 records' );
    is( $giyim_sorted[0]->[0], 'c_01', 'Cheapest Giyim (100) is first' );
};

# ============================================================
# 5. search_table in Simple Mode (Unindexed Word Search)
# ============================================================
subtest '5. search_table in Simple Mode' => sub {
    my $db_dir = "$tmp_dir/simple_db5";
    mkdir($db_dir);
    my $adb = $tools->db_simple($db_dir);

    # Block 1: Title, Block 2: Category
    $adb->insert_id( 'articles', 'art_01', 'Türkiye ekonomi ve piyasalar haberleri', 'Finans' );
    $adb->insert_id( 'articles', 'art_02', 'İstanbul Boğazı ve tarihi köşkler', 'Gezi' );
    $adb->insert_id( 'articles', 'art_03', 'Türkiye genelinde hava durumu ve yağışlar', 'Hava' );
    $adb->insert_id( 'articles', 'art_04', 'Küresel ekonomi ve faiz kararları', 'Finans' );

    # 1. Single word search with Turkish normalization
    my @res1 = $adb->search_table( 'articles', 'türkiye' );
    is( scalar(@res1), 2, 'Search for "türkiye" matched 2 articles' );

    # 2. Multi-word AND search
    my @res2 = $adb->search_table( 'articles', 'türkiye ekonomi' );
    is( scalar(@res2), 1, 'AND search for "türkiye ekonomi" matched exactly 1 article' );
    is( $res2[0]->[0], 'art_01', 'Matched article ID is art_01' );

    # 3. Filter block integration with search (Block 2: Category = Finans)
    my ( $count3, @res3 ) = $adb->search_table( 'articles', 'ekonomi', 0, 10, filter => [ 2, 'Finans' ] );
    is( $count3, 2, 'Search "ekonomi" with filter Category=Finans matched 2 articles' );

    # 4. keys_only option with pagination
    my ( $count4, @keys4 ) = $adb->search_table( 'articles', 'türkiye', 0, 10, keys_only => 1 );
    is( $count4, 2, 'keys_only total count is 2' );
    is( ref( $keys4[0] ), '', 'keys_only returns scalar string ID' );
};

# ============================================================
# 6. Transactions in Simple Mode
# ============================================================
subtest '6. Transactions in Simple Mode' => sub {
    my $db_dir = "$tmp_dir/simple_db6";
    mkdir($db_dir);
    my $adb = $tools->db_simple($db_dir);

    # Start transaction, insert record, rollback
    $adb->transact_start();
    my $id = 'txn_token_12345';
    $adb->insert_id( 'txn_table', $id, 'Temporary Session', time() );
    my @during_txn = $adb->read_id( 'txn_table', $id );
    is( $during_txn[0], $id, 'Record exists during active transaction' );

    $adb->transact_rollback();
    my @after_rb = $adb->read_id( 'txn_table', $id );
    ok( !@after_rb, 'Record cleanly removed from .db file after rollback in simple mode' );
};

# ============================================================
# 7. Helper & Meta Operations in Simple Mode
# ============================================================
subtest '7. Meta Methods & Table Utilities in Simple Mode' => sub {
    my $db_dir = "$tmp_dir/simple_db7";
    mkdir($db_dir);
    my $adb = $tools->db_simple($db_dir);

    $adb->insert_id( 'meta_tbl', 'key_a', 'Data A' );
    $adb->insert_id( 'meta_tbl', 'key_b', 'Data B' );
    $adb->insert_id( 'meta_tbl', 'key_c', 'Data C' );

    is( $adb->table_count('meta_tbl'), 3, 'table_count returns 3' );

    my @all_keys = $adb->table_keys('meta_tbl');
    is( scalar(@all_keys), 3, 'table_keys returns all 3 keys' );

    my $exists = $adb->exist_table('meta_tbl');
    is( $exists, 1, 'exist_table returns 1 for existing .db file' );
};

# ============================================================
# 8. Continuous Backup Logs (recs_back) in Simple Mode
# ============================================================
subtest '8. Daily Backup Logs (recs_back) in Simple Mode' => sub {
    my $db_dir = "$tmp_dir/simple_db8";
    mkdir($db_dir);
    my $adb = AmberDB->new(
        path => { dbase_dir => $db_dir },
        cfg  => { use_simple => 1, user => 'simple_admin' },
    );

    my $sid = 'sess_token_99999_xyz_extra_long';

    # 1. Insert record (add action)
    $adb->insert_id( 'sessions', $sid, 'Active', '192.168.1.50' );

    # 2. Modify record (edit action)
    $adb->modify_id( 'sessions', $sid, 'Closed', '192.168.1.50' );

    # 3. Delete record (del action)
    $adb->delete_id( 'sessions', $sid );

    my $date_iso = "$adb->{date}->{year}-$adb->{date}->{month}-$adb->{date}->{day}";
    my $csv_file = "$db_dir/$date_iso.csv";

    ok( -e $csv_file, "Daily CSV backup file $csv_file created directly in same dbase_dir in simple mode" );
    ok( !-d "$db_dir/backup", "No separate backup directory created in simple mode" );

    open my $fh, "<:encoding(UTF-8)", $csv_file or die "Cannot open $csv_file: $!";
    my @lines = <$fh>;
    close $fh;

    is( scalar(@lines), 3, "CSV contains exactly 3 entries (add, edit, del) in simple mode" );

    # Line 1: add
    chomp $lines[0];
    my @cols_add = split /\t/, $lines[0];
    is( $cols_add[1], 'simple_admin', "Col 1 is user 'simple_admin'" );
    is( $cols_add[2], 'add',          "Col 2 is action 'add'" );
    is( $cols_add[3], 'sessions',     "Col 3 is table 'sessions'" );
    is( $cols_add[4], $sid,           "Col 4 is custom string ID" );

    # Line 2: edit
    chomp $lines[1];
    my @cols_edit = split /\t/, $lines[1];
    is( $cols_edit[2], 'edit', "Col 2 is action 'edit'" );
    is( $cols_edit[4], $sid,   "Col 4 is custom string ID" );

    # Line 3: del
    chomp $lines[2];
    my @cols_del = split /\t/, $lines[2];
    is( $cols_del[2], 'del', "Col 2 is action 'del'" );
    is( $cols_del[4], $sid,  "Col 4 is custom string ID" );

    # 4. Verify no_backup flag disables logging
    my $db_dir_noback = "$tmp_dir/simple_db8_noback";
    mkdir($db_dir_noback);
    my $adb_noback = AmberDB->new(
        path => { dbase_dir => $db_dir_noback },
        cfg  => { use_simple => 1, no_backup => 1 },
    );
    $adb_noback->insert_id( 'tbl', 'id1', 'val1' );
    my $noback_csv = "$db_dir_noback/$date_iso.csv";
    ok( !-e $noback_csv, "No backup CSV created when no_backup => 1" );
};

# ============================================================
# 9. Simple Mode Key Sanitization and Reference Rejection
# ============================================================
subtest '9. Simple Mode Key Sanitization and Reference Rejection' => sub {
    my $db_dir = "$tmp_dir/simple_db9";
    mkdir($db_dir);
    my $adb = $tools->db_simple($db_dir);

    # Rejection of references
    is( $adb->id_check( 'test', [ 1, 2, 3 ] ),      undef, 'ARRAY ref rejected as ID' );
    is( $adb->id_check( 'test', { a => 1 } ),        undef, 'HASH ref rejected as ID' );
    is( $adb->insert_id( 'test', [ 1, 2, 3 ], 'data' ), undef, 'insert_id rejects ARRAY ref ID' );
    is( $adb->insert_id( 'test', { a => 1 }, 'data' ),   undef, 'insert_id rejects HASH ref ID' );

    # Control character rejection
    is( $adb->id_check( 'test', "bad\0id" ),   undef, 'Null byte rejected in key' );
    is( $adb->id_check( 'test', "bad\nid" ),   undef, 'Newline rejected in key' );
    is( $adb->id_check( 'test', "bad\rid" ),   undef, 'Carriage return rejected in key' );
    is( $adb->id_check( 'test', "bad\tid" ),   undef, 'Tab rejected in key' );

    # Whitespace trimming
    is( $adb->id_check( 'test', "  valid_key  " ), 'valid_key', 'Leading/trailing whitespace trimmed' );
    is( $adb->id_check( 'test', "   " ),            undef,       'Whitespace-only rejected' );

    # Length limit
    my $long_key = 'x' x 256;
    is( $adb->id_check( 'test', $long_key ), undef, '>255 byte key rejected in Simple Mode' );
    my $ok_key = 'x' x 255;
    is( $adb->id_check( 'test', $ok_key ), $ok_key, '255 byte key accepted in Simple Mode' );
};

# ============================================================
# 10. Simple Mode Configuration Interoperability (simple <-> use_simple)
# ============================================================
subtest '10. Configuration Interoperability (simple <-> use_simple)' => sub {
    # 1. new with simple => 1 (normalized to use_simple, no simple key kept in hash)
    my $db1 = AmberDB->new( cfg => { simple => 1 } );
    is( $db1->config('simple'),     1, "new(cfg => { simple => 1 }): config('simple') is 1" );
    is( $db1->config('use_simple'), 1, "new(cfg => { simple => 1 }): config('use_simple') is 1 (fallback)" );
    ok( !exists $db1->{_cfg}->{simple}, "hash contains only use_simple, no {simple} key in _cfg" );
    is( $db1->{_cfg}->{use_simple}, 1,  "{use_simple} is 1 in _cfg" );

    # 2. new with use_simple => 1
    my $db2 = AmberDB->new( cfg => { use_simple => 1 } );
    is( $db2->config('use_simple'), 1, "new(cfg => { use_simple => 1 }): config('use_simple') is 1" );
    is( $db2->config('simple'),     1, "new(cfg => { use_simple => 1 }): config('simple') is 1 (fallback)" );
    ok( !exists $db2->{_cfg}->{simple}, "hash contains only use_simple, no {simple} key in _cfg" );
    is( $db2->{_cfg}->{use_simple}, 1,  "{use_simple} is 1 in _cfg" );

    # 3. Dynamic setter with use_simple
    my $db3 = AmberDB->new();
    $db3->config( use_simple => 1 );
    is( $db3->config('use_simple'), 1, "setter use_simple => 1: config('use_simple') is 1" );
    is( $db3->config('simple'),     1, "setter use_simple => 1: config('simple') is 1" );
    ok( !exists $db3->{_cfg}->{simple}, "hash still contains only use_simple" );

    # 4. Dynamic setter with simple (stores into use_simple only)
    $db3->config( simple => 0 );
    is( $db3->config('simple'),     0, "setter simple => 0: config('simple') is 0" );
    is( $db3->config('use_simple'), 0, "setter simple => 0: config('use_simple') is 0" );
    ok( !exists $db3->{_cfg}->{simple}, "setter simple => 0 stores into use_simple only" );

    $db3->config( simple => 1 );
    is( $db3->config('simple'),     1, "setter simple => 1: config('simple') is 1" );
    is( $db3->config('use_simple'), 1, "setter simple => 1: config('use_simple') is 1" );
    ok( !exists $db3->{_cfg}->{simple}, "setter simple => 1 stores into use_simple only" );
};

done_testing();
