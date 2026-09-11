#!/usr/bin/perl

# t/flatdb_index.t - Tests for AmberDB read_all binary index (.inx) pipeline
#
# Covers the full chain:
#   bin_encode -> recs_put -> DB_File -> recs_get -> bin_decode -> read_all

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('AmberDB')               or BAIL_OUT('Cannot load AmberDB');
use_ok('AmberDB::Base::Index')        or BAIL_OUT('Cannot load AmberDB::Base::Index');
use_ok('AmberDB::Base::Facet')        or BAIL_OUT('Cannot load AmberDB::Base::Facet');
use_ok('AmberDB::Tools')              or BAIL_OUT('Cannot load AmberDB::Tools');

subtest 'Index Methods Existence' => sub {
    plan tests => 17;
    can_ok( 'AmberDB::Base::Index', 'get_fieldlist' );
    can_ok( 'AmberDB::Base::Index', 'set_fieldlist' );
    can_ok( 'AmberDB::Base::Index', 'field_to_list' );
    can_ok( 'AmberDB::Base::Index', 'rdbm_target' );
    can_ok( 'AmberDB::Base::Index', 'repeat_fields' );
    can_ok( 'AmberDB::Base::Facet', 'facet_rules' );
    can_ok( 'AmberDB::Base::Facet', 'facet_add' );
    can_ok( 'AmberDB::Base::Facet', 'facet_modify' );
    can_ok( 'AmberDB::Base::Facet', 'facet_del' );
    can_ok( 'AmberDB::Base::Index', 'match_add' );
    can_ok( 'AmberDB::Base::Index', 'search_add' );
    can_ok( 'AmberDB::Base::Index', 'records_add' );
    can_ok( 'AmberDB::Base::Index', 'slug_add' );
    can_ok( 'AmberDB::Base::Index', 'slug_del' );
    can_ok( 'AmberDB::Base::Index', 'slug_modify' );
    can_ok( 'AmberDB::Base::Index', 'set_slug' );
    can_ok( 'AmberDB::Base::Index', 'get_slug' );
};

subtest 'AmberDB Inheritance of Index Methods' => sub {
    plan tests => 17;
    can_ok( 'AmberDB', 'get_fieldlist' );
    can_ok( 'AmberDB', 'set_fieldlist' );
    can_ok( 'AmberDB', 'field_to_list' );
    can_ok( 'AmberDB', 'rdbm_target' );
    can_ok( 'AmberDB', 'repeat_fields' );
    can_ok( 'AmberDB', 'facet_rules' );
    can_ok( 'AmberDB', 'facet_add' );
    can_ok( 'AmberDB', 'facet_modify' );
    can_ok( 'AmberDB', 'facet_del' );
    can_ok( 'AmberDB', 'match_add' );
    can_ok( 'AmberDB', 'search_add' );
    can_ok( 'AmberDB', 'records_add' );
    can_ok( 'AmberDB', 'slug_add' );
    can_ok( 'AmberDB', 'slug_del' );
    can_ok( 'AmberDB', 'slug_modify' );
    can_ok( 'AmberDB', 'set_slug' );
    can_ok( 'AmberDB', 'get_slug' );
};

subtest 'Facet Rules Evaluation' => sub {
    plan tests => 3;
    my $adb = AmberDB->new();

    my $table_info = {
        facet_rules => [ [ 2, 'eq', 'active' ] ]
    };

    my @active_rec   = ( 1, 'Item 1', 'active' );
    my @inactive_rec = ( 2, 'Item 2', 'passive' );

    ok( $adb->facet_rules( $table_info, @active_rec ), 'Active record passes facet rules' );
    ok( !$adb->facet_rules( $table_info, @inactive_rec ), 'Inactive record fails facet rules' );

    my $no_rule_info = {};
    ok( $adb->facet_rules( $no_rule_info, @inactive_rec ), 'Record passes when no facet_rules defined' );
};

# ------------------------------------------------------------------
# SUBTEST: bin_encode / bin_decode birim testi
# ------------------------------------------------------------------
subtest 'bin_encode / bin_decode unit round-trip & id_check' => sub {
    plan tests => 12;

    my $adb = AmberDB->new();
    my @ids = ( 1, 2, 3, 4, 5 );
    my $encoded = $adb->bin_encode( \@ids );

    ok( defined $encoded,           'bin_encode returns defined value' );
    ok( length($encoded) > 0,       'bin_encode returns non-empty buffer' );
    is( length($encoded), 8 * 5,    'bin_encode byte length: 5 x 8 = 40 bytes' );

    my ( $total, @decoded ) = $adb->bin_decode( $encoded, 0, 0, 'asc' );
    is( $total, 5,                  'bin_decode total count = 5' );
    is_deeply( \@decoded, \@ids,   'bin_decode round-trips all IDs (asc)' );

    my ( $cnt2, @sliced ) = $adb->bin_decode( $encoded, 1, 2, 'asc' );
    is( $cnt2, 5,                   'bin_decode total unchanged during pagination' );
    is_deeply( \@sliced, [2, 3],   'bin_decode start=1 limit=2 correct' );

    my ( undef, @desc ) = $adb->bin_decode( $encoded, 0, 0, 'desc' );
    is_deeply( \@desc, [reverse @ids], 'bin_decode desc order correct' );

    # Table id_check checks (use_simple allows string IDs, standard strictly enforces numeric)
    $adb->table_attr( 'simple_tbl', use_simple => 1 );
    $adb->table_attr( 'num_tbl',   use_simple => 0 );

    my $clean_str = $adb->id_check( 'simple_tbl', 'session_token_1234567890_long' );
    is( $clean_str, 'session_token_1234567890_long', 'id_check accepts long string ID in use_simple mode' );

    my $clean_email = $adb->id_check( 'simple_tbl', 'user@example.com' );
    is( $clean_email, 'user@example.com', 'id_check accepts email ID in use_simple mode' );

    my $clean_num = $adb->id_check( 'num_tbl', '12345abc' );
    is( $clean_num, '12345', 'id_check strips non-digits from num ID in standard mode' );

    my $clean_invalid = $adb->id_check( 'num_tbl', 'non_numeric' );
    ok( !defined $clean_invalid, 'id_check rejects non-numeric ID in standard mode' );
};

# ------------------------------------------------------------------
# SUBTEST: index_put / index_get binary safety
# ------------------------------------------------------------------
subtest 'index_put / index_get binary safety' => sub {
    plan tests => 5;

    my $temp_dir = tempdir( CLEANUP => 1 );
    my $inx_path = File::Spec->catfile( $temp_dir, 'test.inx' );

    my $adb  = AmberDB->new();
    my @ids  = ( 1, 2, 3, 100, 5000 );

    ok( $adb->table_write($inx_path), 'table_write opens .inx for writing' );
    $adb->index_put( $inx_path, 'keys',  \@ids );
    $adb->index_put( $inx_path, 'count', scalar @ids );
    $adb->index_put( $inx_path, 'lastid', 5000 );
    $adb->table_close($inx_path);

    ok( -e $inx_path, '.inx file created on disk' );

    my ( $cnt_all, @allkeys ) = $adb->index_get( $inx_path, 'keys' );
    my ($count)  = $adb->index_get( $inx_path, 'count' );
    my ($lastid) = $adb->index_get( $inx_path, 'lastid' );
    is( $cnt_all, scalar @ids, 'keys total count matches' );
    is( $count,   scalar @ids, 'count value matches' );
    is( $lastid,  5000,        'lastid value matches' );

    $adb->table_close($inx_path);
};

# ------------------------------------------------------------------
# SUBTEST: recs_get -> bin_decode pipeline
# ------------------------------------------------------------------
subtest 'index_get binary -> bin_decode pipeline' => sub {
    plan tests => 4;

    my $temp_dir = tempdir( CLEANUP => 1 );
    my $inx_path = File::Spec->catfile( $temp_dir, 'pipe.inx' );

    my $adb  = AmberDB->new();
    my @ids  = ( 10, 20, 30, 40, 50 );

    $adb->table_write($inx_path);
    $adb->index_put( $inx_path, 'keys', \@ids );
    $adb->table_close($inx_path);

    my ( $total_pipe, @decoded ) = $adb->index_get( $inx_path, 'keys', 0, 0, 'asc' );
    is( $total_pipe, 5,              'keys total = 5' );
    is_deeply( \@decoded, \@ids,     'index_get IDs match original' );

    my ( $total, @page ) = $adb->index_get( $inx_path, 'keys', 1, 3, 'asc' );
    is( $total, 5,                   'index_get paginated total = 5' );
    is_deeply( \@page, [20, 30, 40], 'index_get pagination start=1 limit=3 correct' );

    $adb->table_close($inx_path);
};

# ------------------------------------------------------------------
# SUBTEST: insert_id -> .inx -> read_all tam entegrasyon
# ------------------------------------------------------------------
subtest 'insert_id -> .inx -> read_all integration' => sub {
    plan tests => 11;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'items.table' );
    open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
{
    record_index => 1,
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    $adb->insert_id( 'items', 1, 'Alpha' );
    $adb->insert_id( 'items', 2, 'Beta' );
    $adb->insert_id( 'items', 3, 'Gamma' );
    $adb->insert_id( 'items', 4, 'Delta' );
    $adb->insert_id( 'items', 5, 'Epsilon' );

    my $table_path = $adb->table_path('items');
    my $inx_path   = "$table_path.inx";

    ok( -e $inx_path, '.inx file created after inserts' );

    my ( $cnt_all, @allkeys ) = $adb->index_get( $inx_path, 'keys', 0, 0, 'asc' );
    my ($count)  = $adb->index_get( $inx_path, 'count' );
    my ($lastid) = $adb->index_get( $inx_path, 'lastid' );
    ok( defined $cnt_all, 'keys present in .inx' );
    ok( defined $count,   'count present in .inx' );
    ok( defined $lastid,  'lastid present in .inx' );
    is( $count,  5, 'count = 5 after 5 inserts' );
    is( $lastid, 5, 'lastid = 5' );
    is_deeply( \@allkeys, [1,2,3,4,5], '.inx keys IDs = [1..5]' );
    $adb->table_close($inx_path);

    my @all_recs = $adb->read_all('items');
    is( scalar @all_recs, 5, 'read_all returns 5 records (no limit)' );

    my ( $cnt, @page ) = $adb->read_all( 'items', 0, 3, dir => 'asc' );
    is( $cnt, 5,             'read_all total count = 5' );
    is( scalar @page, 3,    'read_all limit=3 returns 3 records' );
    my @page_ids = map { $_->[0] } @page;
    is_deeply( \@page_ids, [1, 2, 3], 'read_all page IDs = [1,2,3]' );
};

# ------------------------------------------------------------------
# SUBTEST: Tools::set_readall rebuild -> read_all
# ------------------------------------------------------------------
subtest 'set_readall rebuild -> read_all' => sub {
    plan tests => 6;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'products.table' );
    open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
{
    record_index => 1,
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    $adb->insert_id( 'products', 10, 'Widget A' );
    $adb->insert_id( 'products', 20, 'Widget B' );
    $adb->insert_id( 'products', 30, 'Widget C' );

    my $table_path = $adb->table_path('products');
    my $inx_path   = "$table_path.inx";
    ok( -e $inx_path, '.inx exists after inserts' );

    my $tools = AmberDB::Tools->new($adb);
    my $ok = $tools->set_readall('products');
    ok( $ok, 'set_readall returns true' );
    ok( -e $inx_path, '.inx still present after rebuild' );

    my ($rebuild_cnt) = $adb->index_get( $inx_path, 'count' );
    is( $rebuild_cnt, 3, 'count = 3 after rebuild' );
    $adb->table_close($inx_path);

    my @all = $adb->read_all('products');
    is( scalar @all, 3, 'read_all = 3 after rebuild' );

    my ( $cnt ) = $adb->read_all( 'products', 0, 2 );
    is( $cnt, 3, 'read_all paginated total = 3' );
};

# ------------------------------------------------------------------
# SUBTEST: delete_id -> .inx guncelleme -> read_all
# ------------------------------------------------------------------
subtest 'delete_id -> .inx -> read_all reflects deletion' => sub {
    plan tests => 5;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'nodes.table' );
    open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
{
    record_index => 1,
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    $adb->insert_id( 'nodes', 1, 'A' );
    $adb->insert_id( 'nodes', 2, 'B' );
    $adb->insert_id( 'nodes', 3, 'C' );

    my @before = $adb->read_all('nodes');
    is( scalar @before, 3, 'read_all = 3 before delete' );

    $adb->delete_id( 'nodes', 2 );

    my @after = $adb->read_all('nodes', dir => 'asc');
    is( scalar @after, 2, 'read_all = 2 after delete' );

    my @after_ids = map { $_->[0] } @after;
    ok( !( grep { $_ == 2 } @after_ids ), 'deleted ID 2 not in results' );

    my ( $cnt ) = $adb->read_all( 'nodes', 0, 5, dir => 'asc' );
    is( $cnt, 2, 'total count = 2 after delete' );
    is_deeply( \@after_ids, [1, 3], 'remaining IDs = [1, 3]' );
};

subtest 'rdbm_target schema parsing' => sub {
    plan tests => 6;
    my $adb = AmberDB->new();

    my $table_info = {
        blocks => [
            { name => 'id' },
            { name => 'title' },
            { name => 'category_id', rdbm => { table => 'categories', display => 2 } },
            { name => 'tag_id',      rdbm => 'tags:1' },
            { name => 'author_id',   rdbm => 'authors;3' },
        ]
    };

    my ( $t2, $b2 ) = $adb->rdbm_target( $table_info, 2 );
    is( $t2, 'categories', 'Block 2 hash format target table' );
    is( $b2, 2,            'Block 2 hash format target block' );

    my ( $t3, $b3 ) = $adb->rdbm_target( $table_info, 3 );
    is( $t3, 'tags', 'Block 3 string format (tags:1) target table' );
    is( $b3, 1,      'Block 3 string format (tags:1) target block' );

    my ( $is_rdbm ) = $adb->rdbm_target( $table_info, 4 );
    is( $is_rdbm, 'authors', 'Block 4 evaluates truthy in ($is_rdbm) list context' );

    my ( $non_rdbm ) = $adb->rdbm_target( $table_info, 1 );
    ok( !$non_rdbm, 'Block 1 non-RDBM returns falsy' );
};

subtest 'table_info schema normalization pipeline (RDBM splitters)' => sub {
    plan tests => 13;
    my $adb = AmberDB->new();

    $adb->table_attr(
        'test_rdbm_norm',
        blocks => [
            { id => 'id' },
            { id => 'cat_comma',     rdbm => 'catalog_category,2' },
            { id => 'cat_semi',      rdbm => 'catalog_category;3' },
            { id => 'cat_pipe',      rdbm => 'catalog_category|4' },
            { id => 'cat_colon',     rdbm => 'catalog_category:5' },
            { id => 'cat_spaces',    rdbm => 'catalog_category | 6 ' },
            { id => 'cat_no_disp',   rdbm => 'catalog_category' },
            { id => 'cat_hash',      rdbm => { table => 'catalog_category', display => 8 } },
        ]
    );

    my $info = $adb->table_info('test_rdbm_norm');

    # Check comma
    is_deeply( $info->{blocks}->[1]->{rdbm}, { table => 'catalog_category', display => 2 }, 'comma separator normalized' );

    # Check semicolon
    is_deeply( $info->{blocks}->[2]->{rdbm}, { table => 'catalog_category', display => 3 }, 'semicolon separator normalized' );

    # Check pipe
    is_deeply( $info->{blocks}->[3]->{rdbm}, { table => 'catalog_category', display => 4 }, 'pipe separator normalized' );

    # Check colon
    is_deeply( $info->{blocks}->[4]->{rdbm}, { table => 'catalog_category', display => 5 }, 'colon separator normalized' );

    # Check whitespace trimmed
    is_deeply( $info->{blocks}->[5]->{rdbm}, { table => 'catalog_category', display => 6 }, 'spaces around separator trimmed' );

    # Check default display
    is_deeply( $info->{blocks}->[6]->{rdbm}, { table => 'catalog_category', display => 1 }, 'default display is 1 when omitted' );

    # Check hashref preserved
    is_deeply( $info->{blocks}->[7]->{rdbm}, { table => 'catalog_category', display => 8 }, 'hashref preserved' );

    # Check rdbm_target resolution on normalized blocks
    my ($t1, $b1) = $adb->rdbm_target($info, 1);
    is( $t1, 'catalog_category', 'rdbm_target resolves table for comma' );
    is( $b1, 2, 'rdbm_target resolves display for comma' );

    my ($t3, $b3) = $adb->rdbm_target($info, 3);
    is( $t3, 'catalog_category', 'rdbm_target resolves table for pipe' );
    is( $b3, 4, 'rdbm_target resolves display for pipe' );

    my ($t5, $b5) = $adb->rdbm_target($info, 5);
    is( $t5, 'catalog_category', 'rdbm_target resolves table for trimmed pipe' );
    is( $b5, 6, 'rdbm_target resolves display for trimmed pipe' );
};

done_testing();
