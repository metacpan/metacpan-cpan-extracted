use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Cwd qw(abs_path);

use lib 'lib';
use AmberDB;

# Require migrate_5_25_0 from migrations/versions/5.25.0/migrate.pl
my $migrate_script = File::Spec->catfile('migrations', 'versions', '5.25.0', 'migrate.pl');
ok( -f $migrate_script, "Found migrate.pl at $migrate_script" );

my $abs_script = abs_path($migrate_script);
do $abs_script;
ok( defined &migrate_5_25_0, "migrate_5_25_0 subroutine is loaded" );

# Helper to write plain text file content
sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    binmode $fh;
    print $fh $content;
    close $fh;
}

# Helper to read plain text file content
sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    binmode $fh;
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# Helper to write DB file record
sub create_db_record {
    my ($adb, $filepath, $id, $val) = @_;
    $adb->table_write($filepath) or die "Cannot write $filepath: $!";
    my $dbh = $adb->{_db}->{$filepath};
    $dbh->put($id, $val);
    $adb->table_close($filepath);
}

# Helper to read DB file record
sub read_db_record {
    my ($adb, $filepath, $id) = @_;
    $adb->table_read($filepath) or die "Cannot read $filepath: $!";
    my $dbh = $adb->{_db}->{$filepath};
    my $val;
    $dbh->get($id, $val);
    $adb->table_close($filepath);
    return $val;
}

# ==============================================================================
# TEST 1: tables/ to table/ migration with collision and explicit date_stamp
# ==============================================================================
{
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    my $table_dir  = File::Spec->catdir( $tmpdir, 'table' );
    my $tables_dir = File::Spec->catdir( $tmpdir, 'tables' );

    make_path($table_dir);
    make_path($tables_dir);

    # Files in table/ (already existing)
    create_db_record( $adb, File::Spec->catfile($table_dir, 'catalog_product.db'), "1", "NEW_PRODUCT" );
    write_file( File::Spec->catfile($table_dir, 'catalog_product.inx'), "EXISTING_PRODUCT_INX" );
    create_db_record( $adb, File::Spec->catfile($table_dir, 'only_in_table.db'), "1", "ONLY_IN_TABLE_DATA" );

    # Files in tables/ (legacy to be migrated)
    create_db_record( $adb, File::Spec->catfile($tables_dir, 'catalog_product.db'), "1", "OLD_PRODUCT" );
    write_file( File::Spec->catfile($tables_dir, 'catalog_product.inx'), "LEGACY_PRODUCT_INX" );
    create_db_record( $adb, File::Spec->catfile($tables_dir, 'catalog_brand.db'), "1", "BRAND_DATA" );
    write_file( File::Spec->catfile($tables_dir, 'catalog_brand.inx'),   "LEGACY_BRAND_INX" );

    # Execute migration with test date_stamp matching user prompt example: 2026-08-25
    migrate_5_25_0(
        target_dir => $tmpdir,
        date_stamp => '2026-08-25',
    );

    # 1. tables/ must be cleaned up and removed
    ok( !-d $tables_dir, "tables/ directory was removed after all files moved" );

    # 2. Existing files in table/ remain intact
    my $fresh_adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    like( read_db_record($fresh_adb, File::Spec->catfile($table_dir, 'catalog_product.db'), "1"),
        qr/NEW_PRODUCT/,
        "Original table/catalog_product.db preserved with upgraded ABR format"
    );
    like( read_db_record($fresh_adb, File::Spec->catfile($table_dir, 'only_in_table.db'), "1"),
        qr/ONLY_IN_TABLE_DATA/,
        "Original table/only_in_table.db preserved"
    );

    # 3. Conflicting files moved from tables/ with date stamp
    my $stamped_db  = File::Spec->catfile($table_dir, 'catalog_product_2026-08-25.db');
    my $stamped_inx = File::Spec->catfile($table_dir, 'catalog_product_2026-08-25.inx');

    ok( -f $stamped_db, "Conflicting catalog_product.db renamed with date stamp -> catalog_product_2026-08-25.db" );
    is( read_db_record($fresh_adb, $stamped_db, "1"), "OLD_PRODUCT", "catalog_product_2026-08-25.db contains moved data" );

    ok( -f $stamped_inx, "Conflicting catalog_product.inx renamed with date stamp -> catalog_product_2026-08-25.inx" );
    is( read_file($stamped_inx), "LEGACY_PRODUCT_INX", "catalog_product_2026-08-25.inx contains moved data" );

    # 4. Non-conflicting files moved without renaming
    my $brand_db  = File::Spec->catfile($table_dir, 'catalog_brand.db');
    ok( -f $brand_db, "Non-conflicting catalog_brand.db moved to table/ directly" );
    like( read_db_record($fresh_adb, $brand_db, "1"), qr/BRAND_DATA/, "catalog_brand.db content verified" );
}

# ==============================================================================
# TEST 2: Secondary conflict handling (stamped filename already exists)
# ==============================================================================
{
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    my $table_dir  = File::Spec->catdir( $tmpdir, 'table' );
    my $tables_dir = File::Spec->catdir( $tmpdir, 'tables' );

    make_path($table_dir);
    make_path($tables_dir);

    # Already existing: both original and stamped file
    create_db_record( $adb, File::Spec->catfile($table_dir, 'catalog_product.db'), "1", "EXISTING_ORIGINAL" );
    create_db_record( $adb, File::Spec->catfile($table_dir, 'catalog_product_2026-08-25.db'), "1", "EXISTING_STAMPED_1" );

    # File to move from tables/
    create_db_record( $adb, File::Spec->catfile($tables_dir, 'catalog_product.db'), "1", "NEW_CONFLICT_FROM_TABLES" );

    migrate_5_25_0(
        target_dir => $tmpdir,
        date_stamp => '2026-08-25',
    );

    ok( !-d $tables_dir, "tables/ directory was removed after secondary conflict move" );

    # Check that suffixed file was created without overwriting existing stamped file
    my $fresh_adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    my $suffixed_db = File::Spec->catfile($table_dir, 'catalog_product_2026-08-25_1.db');
    ok( -f $suffixed_db, "Suffixed file catalog_product_2026-08-25_1.db was created" );
    is( read_db_record($fresh_adb, $suffixed_db, "1"), "NEW_CONFLICT_FROM_TABLES", "Suffixed file contains moved content" );
    is( read_db_record($fresh_adb, File::Spec->catfile($table_dir, 'catalog_product_2026-08-25.db'), "1"), "EXISTING_STAMPED_1", "Existing stamped file preserved" );
}

# ==============================================================================
# TEST 3: Default date stamp (today's date) when date_stamp is not provided
# ==============================================================================
{
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    my $table_dir  = File::Spec->catdir( $tmpdir, 'table' );
    my $tables_dir = File::Spec->catdir( $tmpdir, 'tables' );

    make_path($table_dir);
    make_path($tables_dir);

    create_db_record( $adb, File::Spec->catfile($table_dir, 'catalog_product.db'),  "1", "TODAY_TEST_ORIGINAL" );
    create_db_record( $adb, File::Spec->catfile($tables_dir, 'catalog_product.db'), "1", "TODAY_TEST_MOVED" );

    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    my $today_stamp = sprintf("%04d-%02d-%02d", $year + 1900, $mon + 1, $mday);

    migrate_5_25_0(
        target_dir => $tmpdir,
    );

    ok( !-d $tables_dir, "tables/ removed on default date stamp test" );

    my $fresh_adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    my $expected_stamped = File::Spec->catfile($table_dir, "catalog_product_${today_stamp}.db");
    ok( -f $expected_stamped, "Conflict file stamped with today's date ($today_stamp)" );
    is( read_db_record($fresh_adb, $expected_stamped, "1"), "TODAY_TEST_MOVED", "Today's stamped file has moved content" );
}

# ==============================================================================
# TEST 4: amberdb_setup.pl CLI update-storage execution
# ==============================================================================
{
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    my $table_dir  = File::Spec->catdir( $tmpdir, 'table' );
    my $tables_dir = File::Spec->catdir( $tmpdir, 'tables' );

    make_path($table_dir);
    make_path($tables_dir);

    create_db_record( $adb, File::Spec->catfile($table_dir, 'catalog_product.db'),  "1", "CLI_EXISTING" );
    create_db_record( $adb, File::Spec->catfile($tables_dir, 'catalog_product.db'), "1", "CLI_MOVED" );

    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    my $today_stamp = sprintf("%04d-%02d-%02d", $year + 1900, $mon + 1, $mday);

    my $perl_exe = $^X;
    my $setup_script = File::Spec->catfile('bin', 'amberdb_setup.pl');
    my $cmd = qq{"$perl_exe" -Ilib "$setup_script" --action=update-storage --dbase_dir="$tmpdir" --all};
    my $out = `$cmd`;

    ok( !-d $tables_dir, "amberdb_setup.pl update-storage moved all files and removed tables/" );
    my $expected_cli_stamped = File::Spec->catfile($table_dir, "catalog_product_${today_stamp}.db");
    ok( -f $expected_cli_stamped, "amberdb_setup.pl created stamped file catalog_product_${today_stamp}.db" );
    my $fresh_adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
    is( read_db_record($fresh_adb, $expected_cli_stamped, "1"), "CLI_MOVED", "Content preserved by amberdb_setup.pl" );
}

done_testing();
