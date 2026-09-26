#!/usr/bin/perl

# t/amberdb/amberdb_tools.t - Comprehensive tests for AmberDB::Tools

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';
use AmberDB;
use AmberDB::Tools;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0 }
);

# Schema definition via official table_attr API
$adb->table_attr( 'catalog_product', {
    record_index => 1,
    search_block => [1],
    match_block  => [2],
    use_facet    => 1,
    sort_block   => [ { blk => 3, type => 'numeric' } ],
} );

my $tools = AmberDB::Tools->new($adb);
isa_ok( $tools, 'AmberDB::Tools' );

# ---------------------------------------------------------------------------
subtest '1. Table creation, population & set_index' => sub {
    plan tests => 6;

    # Insert test data
    $adb->insert_id( 'catalog_product', 1, 'Laptop Pro', 'Electronics', 1500 );
    $adb->insert_id( 'catalog_product', 2, 'Mechanical Keyboard', 'Accessories', 120 );
    $adb->insert_id( 'catalog_product', 3, 'Gaming Mouse', 'Accessories', 80 );

    ok( $adb->exist_table('catalog_product'), "Table exists detected" );

    # Rebuild all indexes
    my $ok = $tools->set_index('catalog_product');
    ok( $ok, "set_index successfully completed" );

    my $table_path = $adb->table_path('catalog_product');
    ok( -e "$table_path.inx", "Readall index .inx generated" );
    ok( -e "$table_path.src", "Search index .src generated" );
    ok( -e "$table_path.fld", "Match field index .fld generated" );
    ok( scalar($adb->index_get("$table_path.inx", "3:keys")), "Sort index 3:keys generated in .inx" );
};

# ---------------------------------------------------------------------------
subtest '2. check_readall & check_search consistency' => sub {
    plan tests => 2;

    my @records = $adb->read_all('catalog_product');
    my $diff_readall = $tools->check_readall( 'catalog_product', @records );
    is_deeply( $diff_readall, {}, "check_readall reports 0 discrepancies for valid index" );

    my $diff_search = $tools->check_search( 'catalog_product', @records );
    ok( ref($diff_search) eq 'HASH', "check_search returns diagnostic hash" );
};

# ---------------------------------------------------------------------------
subtest '3. tie2csv, csv2tie & vacuum' => sub {
    plan tests => 5;

    my $ok_csv = $tools->tie2csv('catalog_product');
    ok( $ok_csv, "tie2csv executed" );

    my $table_path = $adb->table_path('catalog_product');
    ok( -e "$table_path.csv", "Exported CSV file exists" );

    my $ok_import = $tools->csv2tie('catalog_product');
    ok( $ok_import, "csv2tie restored data from CSV" );

    my @after_import = $adb->read_all('catalog_product');
    is( scalar(@after_import), 3, "All 3 records restored after CSV import" );

    my $ok_vac = $tools->vacuum( 'catalog_product', 1 );
    ok( $ok_vac, "vacuum executed successfully with reindexing" );
};

# ---------------------------------------------------------------------------
subtest '4. replace_blockdata' => sub {
    plan tests => 2;

    my $status = $tools->replace_blockdata(
        { 'catalog_product' => 2 },
        { 'Accessories' => 'Computer Peripherals' }
    );

    ok( ref($status) eq 'HASH', "replace_blockdata returned status" );

    my @rec2 = $adb->read_id( 'catalog_product', 2 );
    is( $rec2[2], 'Computer Peripherals', "Target column value updated across table" );
};

# ---------------------------------------------------------------------------
subtest '5. del_table' => sub {
    plan tests => 2;

    my $del_ok = $tools->del_table('catalog_product');
    ok( $del_ok, "del_table executed" );
    ok( !$adb->exist_table('catalog_product'), "Table files and indexes cleanly deleted" );
};

done_testing();
