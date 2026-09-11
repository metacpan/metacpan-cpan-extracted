use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use File::Temp qw(tempdir);
use File::Spec;
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';

use AmberDB;
use AmberDB::Tools;

my $tmp_dir = tempdir( CLEANUP => 1 );
my $db_dir  = "$tmp_dir/main_db";
my $sch_dir = "$tmp_dir/schema";
mkdir $db_dir;
mkdir $sch_dir;
mkdir "$db_dir/table";

# Create standard schema for products
my $prod_sch = "$sch_dir/products.table";
open my $pfh, '>', $prod_sch or die $!;
print $pfh <<'SCHEMA';
{
    record_index => 1,
    blocks => [
        { name => "id",       type => "number" },
        { name => "title",    type => "string" },
        { name => "session",  type => "string", rdbm => "sessions;1" },
    ],
    match_block  => [ 1 ],
    search_block => [ 1 ],
}
SCHEMA
close $pfh;

# Create use_simple schema for sessions
my $sess_sch = "$sch_dir/sessions.table";
open my $sfh, '>', $sess_sch or die $!;
print $sfh <<'SCHEMA';
{
    use_simple   => 1,
    keep_deleted => 1,
    use_ramdisk  => 1,
    ramdisk_ttl  => 3600,
    use_cache    => 1,
    cache_ttl    => 3600,
    blocks       => [ { name => "id", type => "string" }, { name => "data", type => "string" } ],
    match_block  => [ 1 ],
}
SCHEMA
close $sfh;

my $adb = AmberDB->new(
    path => {
        dbase_dir  => $db_dir,
        schema_dir => $sch_dir,
    }
);

# ============================================================
# 1. Schema Sanitization for use_simple Table
# ============================================================
subtest '1. Schema Sanitization & Path Verification' => sub {
    plan tests => 9;

    # Sessions table info should have index/block/cache definitions stripped, but behavioral flags preserved
    my $s_info = $adb->table_info('sessions');
    is( $s_info->{use_simple}, 1, 'use_simple is 1' );
    is( $s_info->{keep_deleted}, 1, 'keep_deleted preserved' );
    ok( !exists $s_info->{blocks}, 'blocks stripped for use_simple table' );
    ok( !exists $s_info->{match_block}, 'match_block stripped for use_simple table' );
    ok( !exists $s_info->{use_ramdisk}, 'use_ramdisk stripped for use_simple table' );
    ok( !exists $s_info->{ramdisk_ttl}, 'ramdisk_ttl stripped for use_simple table' );
    ok( !exists $s_info->{use_cache}, 'use_cache stripped for use_simple table' );
    ok( !exists $s_info->{cache_ttl}, 'cache_ttl stripped for use_simple table' );

    # Table path must be within standard table/ directory, NOT root dbase_dir
    my $path = $adb->table_path('sessions');
    like( $path, qr{[/\\]table[/\\]sessions$}, 'table_path is in dbase_dir/table/ directory' );
};

# ============================================================
# 2. CRUD with Arbitrary String IDs in use_simple Table
# ============================================================
subtest '2. CRUD with Arbitrary String IDs (UUID, Email, Long Tokens)' => sub {
    plan tests => 18;

    my @test_keys = (
        '123e4567-e89b-12d3-a456-426614174000',
        'admin.user@example.com',
        'sess_tok_99999_abcdef_1234567890_very_long_auth_token_value',
        'tr_öğrenci_no_12345',
        '100200300',
    );

    foreach my $k (@test_keys) {
        my $ins = $adb->insert_id( 'sessions', $k, "Data for $k", time() );
        is( $ins, $k, "insert_id succeeded with key: $k" );

        my @rec = $adb->read_id( 'sessions', $k );
        is( $rec[0], $k, "read_id returned exact key: $k" );
        is( $rec[1], "Data for $k", "read_id data field matched" );
    }

    # Modify
    my $mod_res = $adb->modify_id( 'sessions', $test_keys[0], "Updated data", time() );
    ok( $mod_res, "modify_id succeeded on string key" );

    my @mod_rec = $adb->read_id( 'sessions', $test_keys[0] );
    is( $mod_rec[1], "Updated data", "modify_id value persisted" );

    # Bulk operations
    my $bulk_status = $adb->insert_list( 'sessions', [ 'bulk_key_1', 'val1' ], [ 'bulk_key_2', 'val2' ] );
    is( scalar( keys %$bulk_status ), 2, 'insert_list inserted 2 records' );
};

# ============================================================
# 3. keep_deleted and No Index Files Generated
# ============================================================
subtest '3. keep_deleted Behavior & Zero Index File Guarantee' => sub {
    plan tests => 4;

    my $del_key = 'admin.user@example.com';
    my $del_res = $adb->delete_id( 'sessions', $del_key );
    ok( $del_res, 'delete_id succeeded' );

    my @after_del = $adb->read_id( 'sessions', $del_key );
    ok( !@after_del, 'Deleted record not returned by read_id' );

    # Check that .del archive file exists and contains the deleted record
    my $del_file = "$db_dir/table/sessions.del";
    ok( -e $del_file, 'sessions.del archive created by keep_deleted' );

    # Check that NO index files exist for sessions
    my @all_files = glob("$db_dir/table/*");
    my @index_files = grep { /sessions\.(inx|fld|src|srt|fac|slg)$/ } @all_files;
    is_deeply( \@index_files, [], 'No index files (.inx, .fld, .src, .srt, .fac, .slg) created for sessions' );
};

# ============================================================
# 4. Foreign Key (RDBM) & field_fetch Protection
# ============================================================
subtest '4. Foreign Key (RDBM) Guarding & field_fetch Unindexed Scan' => sub {
    plan tests => 5;

    # Products schema attempted to link RDBM to sessions table
    my $prod_info = $adb->table_info('products');
    my ( $rdbm_t, $rdbm_b ) = $adb->rdbm_target( $prod_info, 2 );
    is( $rdbm_t, undef, 'rdbm_target rejected linking to use_simple sessions table' );

    # _resolve_field_value should return empty string for simple target
    my $resolved = $adb->_resolve_field_value( $prod_info, [ 1, "Product A", "sess_123" ], "2->1" );
    is( $resolved, '', '_resolve_field_value safely returns empty string when linking to simple table' );

    # field_fetch on simple table (unindexed direct table scan)
    my @ff_found = $adb->field_fetch( 'sessions', 1, 'Data for 100200300' );
    is( scalar(@ff_found), 1, 'field_fetch unindexed scan matches record on use_simple table' );

    my @ff_none = $adb->field_fetch( 'sessions', 1, 'NonExistent' );
    is_deeply( \@ff_none, [], 'field_fetch returns empty list when term not found' );

    # Standard table numeric ID check remains strict
    my $clean_prod_id = $adb->id_check( 'products', 'prod_999' );
    is( $clean_prod_id, '999', 'Standard table strictly strips non-digits to numeric ID' );
};

# ============================================================
# 5. Pure 64-bit uint Binary Packing (bin_encode & bin_decode)
# ============================================================
subtest '5. Pure 64-bit uint Binary Engine' => sub {
    plan tests => 6;

    my @num_ids = ( 1, 42, 1000, 999999, 123456789012 );
    my $encoded = $adb->bin_encode( \@num_ids );
    is( length($encoded), 5 * 8, 'bin_encode produces exactly 5 x 8 = 40 bytes' );

    my ( $total, @decoded ) = $adb->bin_decode( $encoded, 0, 0, 'asc' );
    is( $total, 5, 'bin_decode total count = 5' );
    is_deeply( \@decoded, \@num_ids, 'bin_decode asc round-trip matches exactly' );

    my ( $cnt_p, @page ) = $adb->bin_decode( $encoded, 1, 3, 'asc' );
    is( $cnt_p, 5, 'pagination total = 5' );
    is_deeply( \@page, [ 42, 1000, 999999 ], 'pagination slice matches' );

    my ( undef, @desc ) = $adb->bin_decode( $encoded, 0, 0, 'desc' );
    is_deeply( \@desc, [ reverse @num_ids ], 'desc order matches reversed array' );
};

done_testing();
