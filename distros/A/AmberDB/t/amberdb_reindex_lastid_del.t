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
my $db_dir  = "$tmp_dir/dbstore";
my $sch_dir = "$db_dir/schema";
mkdir $db_dir;
mkdir $sch_dir;
mkdir "$db_dir/table";

my $adb = AmberDB->new(
    path => {
        dbase_dir  => $db_dir,
        schema_dir => $sch_dir,
    }
);

subtest 'keep_deleted => 1 preserves lastid across reindex' => sub {
    $adb->table_attr( 'items', {
        record_index => 1,
        keep_deleted => 1,
        blocks => [
            { name => "id",    type => "number" },
            { name => "title", type => "string" },
        ],
    });

    # Insert 3 records
    my $id1 = $adb->insert_id('items', undef, 'Item 1');
    my $id2 = $adb->insert_id('items', undef, 'Item 2');
    my $id3 = $adb->insert_id('items', undef, 'Item 3');

    is( $id1, 1, 'First ID is 1' );
    is( $id2, 2, 'Second ID is 2' );
    is( $id3, 3, 'Third ID is 3' );

    # Delete record 3 (moves to .del archive)
    $adb->delete_id('items', 3);

    my $del_file = "$db_dir/table/items.del";
    ok( -e $del_file, 'items.del file exists' );

    # Reindex table
    my $tools = AmberDB::Tools->new($adb);
    $tools->set_index('items');

    # Check lastid: must be 3 because 3 exists in .del!
    my $last_id = $adb->table_lastid('items');
    is( $last_id, 3, 'table_lastid is 3 after reindex (protected by .del)' );

    # Insert new record: must be 4, NOT 3!
    my $id4 = $adb->insert_id('items', undef, 'Item 4');
    is( $id4, 4, 'Next auto-increment ID is 4, avoiding collision with deleted record 3' );
};

subtest 'without keep_deleted, reindex acts as a vacuum' => sub {
    $adb->table_attr( 'temp_items', {
        record_index => 1,
        keep_deleted => 0,
        blocks => [
            { name => "id",    type => "number" },
            { name => "title", type => "string" },
        ],
    });

    # Insert 3 records
    my $id1 = $adb->insert_id('temp_items', undef, 'Temp 1');
    my $id2 = $adb->insert_id('temp_items', undef, 'Temp 2');
    my $id3 = $adb->insert_id('temp_items', undef, 'Temp 3');

    is( $id3, 3, 'Temp ID is 3' );

    # Delete record 3 (truly purged, no .del)
    $adb->delete_id('temp_items', 3);

    my $del_file = "$db_dir/table/temp_items.del";
    ok( !-e $del_file, 'temp_items.del does not exist' );

    # Reindex table
    my $tools = AmberDB::Tools->new($adb);
    $tools->set_index('temp_items');

    # Check lastid: should shrink to 2 (vacuum behavior)
    my $last_id = $adb->table_lastid('temp_items');
    is( $last_id, 2, 'table_lastid is vacuumed down to 2' );

    # Insert new record: gets ID 3
    my $new_id3 = $adb->insert_id('temp_items', undef, 'Temp 3 New');
    is( $new_id3, 3, 'Next ID fills vacuumed slot 3' );
};

done_testing();
