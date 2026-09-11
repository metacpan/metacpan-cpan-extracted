use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';
use AmberDB;
use AmberDB::Tools;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { language => 'tr', simple => 1 },
);
my $tools = AmberDB::Tools->new($adb);

# ==============================================================================
# SUBTEST 1: Format Detection & Legacy Decoding Functions
# ==============================================================================
subtest '1. Format Detection and Legacy Decoding' => sub {
    plan tests => 8;

    # v1: 2003 FlatDB
    my $r_v1 = "101\tProduct 2003\tDescription\\twith tab";
    is( $adb->detect_record_format($r_v1), 'v1', 'Detected 2003 format as v1' );
    my @dec_v1 = $adb->tsv_decode($r_v1);
    is_deeply( \@dec_v1, [ "101", "Product 2003", "Description\twith tab" ], '2003 v1 decoded accurately' );

    # v2: 2005 \T array
    my $r_v2 = "102\tLaptop\tred\\Tblue\\Tgreen";
    is( $adb->detect_record_format($r_v2), 'v2', 'Detected 2005 format as v2' );
    my @dec_v2 = $adb->tsv_decode($r_v2);
    is_deeply( \@dec_v2, [ "102", "Laptop", [ "red", "blue", "green" ] ], '2005 v2 decoded accurately' );

    # v3: 2021 <TAB> hierarchy
    my $r_v3 = "103<TAB0>Phone<TAB0>opt1<TAB1>opt2<TAB1>opt3";
    is( $adb->detect_record_format($r_v3), 'v3', 'Detected 2021 format as v3' );
    my @dec_v3 = $adb->tsv_decode($r_v3);
    is_deeply( \@dec_v3, [ "103", "Phone", [ "opt1", "opt2", "opt3" ] ], '2021 v3 decoded accurately' );

    # v4: 2026 ARRAY: / HASH:
    my $r_v4 = "104\tiPhone\tARRAY:tag1|tag2\tHASH:color=Titanium|stock=10";
    is( $adb->detect_record_format($r_v4), 'v4', 'Detected 2026 format as v4' );
    my @dec_v4 = $adb->tsv_decode($r_v4);
    is_deeply( \@dec_v4, [ "104", "iPhone", [ "tag1", "tag2" ], { color => "Titanium", stock => "10" } ], '2026 v4 decoded accurately' );
};

# ==============================================================================
# SUBTEST 2: update_table on Mixed Legacy Table & Backup Creation
# ==============================================================================
subtest '2. update_table on Mixed Legacy Table' => sub {
    plan tests => 13;

    my $tbl = 'catalog_products';
    my $table_file = File::Spec->catfile($tmpdir, "$tbl.db");

    # Write a table with records from multiple eras
    $adb->table_write($table_file) or die "Cannot create table";
    my $dbh = $adb->{_db}->{$table_file};
    $dbh->put("1", "Product 2003\t100");
    $dbh->put("2", "Product 2005\tred\\Tblue");
    $dbh->put("3", "Product 2021<TAB0>opt1<TAB1>opt2");
    $dbh->put("4", "Product 2026\tARRAY:t1|t2\tHASH:k=v");
    $adb->table_close($table_file);

    # Run update_table
    my $res = $tools->update_table($tbl);
    is( $res->{status}, 'updated', 'update_table returned status updated' );
    is( $res->{total}, 4, 'Total records processed is 4' );
    is( $res->{updated}, 4, '4 legacy records were converted' );
    ok( -e $res->{backup_file}, "Backup file was created: $res->{backup_file}" );
    like( $res->{backup_file}, qr/catalog_products-v\d-\d{4}-\d{4}\.db/, 'Backup file matches -v<ver>-<date>.db naming pattern' );

    # Verify table is now 100% ABR v1
    $adb->table_read($table_file);
    my %migrated;
    $adb->recs_scan($table_file, sub {
        my ($k, $v) = @_;
        $migrated{$k} = $v;
    });
    $adb->table_close($table_file);

    for my $k (1..4) {
        ok( substr($migrated{$k}, 0, 5) eq "\x00ABR\x05", "Record $k is in ABR v5 binary format" );
    }

    # Verify data fidelity via read_id
    my @r2 = $adb->read_id($tbl, 2);
    is_deeply( $r2[2], ["red", "blue"], 'Record 2 array restored after migration' );

    my @r4 = $adb->read_id($tbl, 4);
    is_deeply( $r4[2], ["t1", "t2"], 'Record 4 array restored after migration' );
    is_deeply( $r4[3], { k => "v" }, 'Record 4 hash restored after migration' );

    # Second run should report already_current
    my $res2 = $tools->update_table($tbl);
    is( $res2->{status}, 'already_current', 'Second update_table run detects already_current' );
};

# ==============================================================================
# SUBTEST 3: update_table with Companion .del File
# ==============================================================================
subtest '3. update_table with Companion .del File' => sub {
    plan tests => 6;

    my $tbl = 'orders';
    my $table_file = File::Spec->catfile($tmpdir, "$tbl.db");
    my $del_file   = File::Spec->catfile($tmpdir, "$tbl.del");

    # Write main table in 2021 <TAB> format
    $adb->table_write($table_file);
    my $dbh = $adb->{_db}->{$table_file};
    $dbh->put("101", "Order Active<TAB0>500");
    $adb->table_close($table_file);

    # Write .del archive in 2005 \T format
    $adb->table_write($del_file);
    my $ddbh = $adb->{_db}->{$del_file};
    $ddbh->put("999", "Order Cancelled\titem1\\Titem2\t0");
    $adb->table_close($del_file);

    # Run update_table
    my $res = $tools->update_table($tbl);
    is( $res->{status}, 'updated', 'Orders table updated' );
    is( $res->{del_migrated}, 1, '1 record in .del archive migrated' );
    ok( -e $res->{del_backup}, "Backup file for .del created: $res->{del_backup}" );

    # Verify .del file is now ABR v1
    $adb->table_read($del_file);
    my %del_migrated;
    $adb->recs_scan($del_file, sub {
        my ($k, $v) = @_;
        $del_migrated{$k} = $v;
    });
    $adb->table_close($del_file);

    ok( exists $del_migrated{"999"}, 'Record 999 exists in .del' );
    ok( substr($del_migrated{"999"}, 0, 5) eq "\x00ABR\x05", 'Record 999 in .del is now ABR v5' );
    my @dec_del = $adb->db_decode($del_migrated{"999"});
    is_deeply( $dec_del[1], ["item1", "item2"], '.del array structure preserved intact' );
};

# ==============================================================================
# SUBTEST 4: update_all Discovery and Batch Execution
# ==============================================================================
subtest '4. update_all Batch Execution' => sub {
    plan tests => 3;

    my @reports = $tools->update_all();
    ok( scalar(@reports) >= 2, 'update_all processed all discovered tables' );

    # Since catalog_products and orders were already updated, both should be already_current
    my $all_current = 1;
    for my $r (@reports) {
        $all_current = 0 unless $r->{status} eq 'already_current';
    }
    ok( $all_current, 'All tables reported already_current on subsequent update_all' );

    # Force re-migration with force => 1
    my @forced_reports = $tools->update_all( force => 1 );
    my $all_forced = 1;
    for my $r (@forced_reports) {
        $all_forced = 0 unless $r->{status} eq 'updated';
    }
    ok( $all_forced, 'All tables re-migrated when force => 1' );
};

# ==============================================================================
# SUBTEST 5: .unq Preservation, .aut / .cnt Handling, and exist_table() Verification
# ==============================================================================
subtest '5. .unq Preservation, .aut / .cnt Handling, and exist_table()' => sub {
    plan tests => 13;

    my $tbl = 'products';
    my $table_file = File::Spec->catfile($tmpdir, "$tbl.db");
    my $unq_file   = File::Spec->catfile($tmpdir, "$tbl.unq");
    my $aut_file   = File::Spec->catfile($tmpdir, "$tbl.aut");
    my $cnt_file   = File::Spec->catfile($tmpdir, "$tbl.cnt");

    # 1. Setup table in 2021 <TAB> format
    $adb->table_write($table_file);
    my $dbh = $adb->{_db}->{$table_file};
    $dbh->put("1", "Keyboard<TAB0>Wireless<TAB0>150");
    $dbh->put("2", "Mouse<TAB0>Optical<TAB0>80");
    $adb->table_close($table_file);

    # 2. Setup .unq (authoritative unique dictionary / synonyms)
    $adb->table_write($unq_file);
    $adb->recs_put($unq_file, ["title:s:Wireless Keyboard", 42]);
    $adb->table_close($unq_file);

    # 3. Setup .aut (audit log with legacy format)
    $adb->table_write($aut_file);
    my $adbh = $adb->{_db}->{$aut_file};
    $adbh->put("1", "admin<TAB0>add<TAB0>20210101");
    $adb->table_close($aut_file);

    # 4. Setup .cnt (read counter)
    $adb->table_write($cnt_file);
    $adb->recs_put($cnt_file, [1, 350], [2, 120]);
    $adb->table_close($cnt_file);

    # Verify exist_table() works for all companion data file extensions
    is( $adb->exist_table($tbl, 'db'),  1, 'exist_table detects .db' );
    is( $adb->exist_table($tbl, 'unq'), 1, 'exist_table detects .unq' );
    is( $adb->exist_table($tbl, 'aut'), 1, 'exist_table detects .aut' );
    is( $adb->exist_table($tbl, 'cnt'), 1, 'exist_table detects .cnt' );
    is( $adb->exist_table($tbl, 'slg'), 0, 'exist_table returns 0 for non-existent .slg' );

    # Run update_table
    my $res = $tools->update_table($tbl);
    is( $res->{status}, 'updated', 'Products table updated successfully' );

    # Verify .unq was PRESERVED and NOT unlinked
    is( $res->{has_unq}, 1, 'Report acknowledges .unq was found' );
    ok( -e $res->{unq_backup}, "Backup copy of .unq created: $res->{unq_backup}" );
    is( $adb->exist_table($tbl, 'unq'), 1, 'Live .unq file is preserved and still exists!' );

    # Verify data inside live .unq was NOT deleted or corrupted
    $adb->table_read($unq_file);
    my $unq_val = $adb->recs_get($unq_file, "title:s:Wireless Keyboard");
    $adb->table_close($unq_file);
    is( $unq_val->{"title:s:Wireless Keyboard"}, 42, '.unq dictionary mapping retained completely' );

    # Verify .aut was migrated and backed up
    is( $res->{aut_migrated}, 1, '.aut audit entry migrated' );
    ok( -e $res->{aut_backup}, "Backup of .aut created: $res->{aut_backup}" );

    # Verify .cnt was preserved and backed up
    is( $res->{has_cnt}, 1, '.cnt counter preserved' );
};

done_testing();

