use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP qw(decode_json);

use lib 'lib';
use AmberDB;
use AmberDB::Tools;

my $perl_exe = $^X;
my $script_path = File::Spec->catfile('bin', 'amberdb_setup.pl');
ok( -f $script_path, "Found bin/amberdb_setup.pl" );

# ==============================================================================
# TEST 1: Check amberdb_setup.pl --action=update-amberdb --check
# ==============================================================================
{
    my $cmd = qq{"$perl_exe" -Ilib "$script_path" --action=update-amberdb --check};
    my $out = `$cmd`;
    like( $out, qr/AmberDB Core Engine Update Utility/i, "update-amberdb banner output correctly" );
    like( $out, qr/Current Engine Version\s*:\s*\d+\.\d+/i, "Current Engine Version printed" );
}

# ==============================================================================
# TEST 2: Run --action=update-storage on a legacy database directory
#         Testing v5.21.0 (scheme -> schema) and v5.25.0 (tables -> table & ABR v5)
# ==============================================================================
my $tmpdir = tempdir( CLEANUP => 1 );

# 1. Create legacy scheme/ directory with a schema file
my $scheme_dir = File::Spec->catdir( $tmpdir, 'scheme' );
mkdir $scheme_dir;
my $sample_schema = File::Spec->catfile( $scheme_dir, "legacy_catalog.dbase" );
open my $sfh, '>', $sample_schema or die "Cannot create $sample_schema";
print $sfh "name\ttitle\n";
close $sfh;

# 2. Create legacy tables/ directory with TSV format table
my $tables_dir = File::Spec->catdir( $tmpdir, 'tables' );
mkdir $tables_dir;

my $adb = AmberDB->new( path => { dbase_dir => $tmpdir } );
my $sample_table = 'legacy_catalog';
my $table_file = File::Spec->catfile( $tables_dir, "$sample_table.db" );

$adb->table_write($table_file) or die "Cannot create table $table_file";
my $dbh = $adb->{_db}->{$table_file};
$dbh->put("101", "Item 2003\tPrice100");
$dbh->put("102", "Item 2005\tred\\Tblue");
$adb->table_close($table_file);

ok( -d $scheme_dir, "Legacy scheme/ directory created" );
ok( -f $table_file, "Created legacy table in tables/ directory" );

# Execute update-storage
{
    my $cmd = qq{"$perl_exe" -Ilib "$script_path" --action=update-storage --dbase_dir="$tmpdir" --all};
    my $out = `$cmd`;
    like( $out, qr/AmberDB Storage, Directory & Compatibility Migration Engine/i, "update-storage banner displayed" );
    like( $out, qr/v5\.21\.0/i, "v5.21.0 migration stage executed" );
    like( $out, qr/v5\.25\.0/i, "v5.25.0 migration stage executed" );
    like( $out, qr/Migrated!/i, "Legacy table migrated to ABR v5 reported" );
}

# Verify v5.21.0: scheme/ renamed to schema/
my $schema_dir = File::Spec->catdir( $tmpdir, 'schema' );
ok( -d $schema_dir, "v5.21.0: schema/ directory exists" );
ok( -f File::Spec->catfile($schema_dir, "legacy_catalog.dbase"), "v5.21.0: Schema file successfully moved to schema/" );

# Verify v5.25.0: tables/ renamed to table/
my $table_dir = File::Spec->catdir( $tmpdir, 'table' );
ok( -d $table_dir, "v5.25.0: table/ directory exists" );
ok( -f File::Spec->catfile($table_dir, "$sample_table.db"), "v5.25.0: Table file exists in table/ directory" );

# Verify standard layout directories created
for my $subdir (qw(table schema journal session lock config ramdisk)) {
    my $d = File::Spec->catdir( $tmpdir, $subdir );
    ok( -d $d, "Directory '$subdir' exists and verified" );
}

# Verify storage_version.json created and stamped with 5.25.0
my $ver_file = File::Spec->catfile( $tmpdir, 'config', 'storage_version.json' );
ok( -f $ver_file, "storage_version.json created" );

if ( -f $ver_file ) {
    open my $fh, '<', $ver_file;
    local $/;
    my $json = <$fh>;
    close $fh;
    my $data = eval { decode_json($json) };
    is( $data->{storage_version}, "5.25.0", "storage_version is stamped as 5.25.0" );
    is( $data->{record_format}, "abr_v5", "record_format is abr_v5" );
}

# Verify check mode on updated database
{
    my $cmd = qq{"$perl_exe" -Ilib "$script_path" --action=update-storage --dbase_dir="$tmpdir" --check};
    my $out = `$cmd`;
    like( $out, qr/already at latest version/i, "update-storage detects database is already up to date" );
}

done_testing();
