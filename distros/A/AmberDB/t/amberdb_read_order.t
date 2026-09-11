use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use AmberDB;

my $temp_dir   = tempdir( CLEANUP => 1 );
my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
mkdir $conf_dir;
mkdir $schema_dir;

# 1. Indexed Schema
my $schema_file = File::Spec->catfile( $schema_dir, 'products.table' );
open my $fh, '>', $schema_file or die "Cannot create schema file: $!";
print $fh <<'SCHEMA';
{
    name         => "Products",
    record_index => 1,
    match_block  => [ 2 ],
    blocks       => [
        { id => "id",       name => "ID",       type => "auto_id" },
        { id => "title",    name => "Title",    type => "text" },
        { id => "category", name => "Category", type => "text" },
    ],
}
SCHEMA
close $fh;

# 2. Unindexed Schema
my $unindexed_file = File::Spec->catfile( $schema_dir, 'unindexed.table' );
open $fh, '>', $unindexed_file or die "Cannot create schema file: $!";
print $fh <<'SCHEMA';
{
    name        => "Unindexed",
    no_index    => 1,
    blocks      => [
        { id => "id",    name => "ID",    type => "auto_id" },
        { id => "title", name => "Title", type => "text" },
    ],
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

# Populate 10 products: IDs 1..10
for my $id ( 1 .. 10 ) {
    my $cat = ( $id % 2 == 0 ) ? 'even' : 'odd';
    $adb->insert_id( 'products', $id, "Product #$id", $cat );
    $adb->insert_id( 'unindexed', $id, "Unindexed #$id" );
}

# ============================================================================
# SUBTEST 1: read_all Default DESC and dir => 'asc' on Indexed Table
# ============================================================================
subtest '1. read_all on indexed table (.inx)' => sub {
    plan tests => 10;

    # 1.1 Unpaginated default DESC (10..1)
    my @all = $adb->read_all('products');
    is( scalar(@all), 10, 'read_all returns all 10 records' );
    is_deeply( [ map { $_->[0] } @all ], [ reverse 1 .. 10 ], 'read_all defaults to DESC (10..1)' );

    # 1.2 Unpaginated explicit dir => 'asc' (1..10)
    my @all_asc = $adb->read_all('products', { dir => 'asc' });
    is_deeply( [ map { $_->[0] } @all_asc ], [ 1 .. 10 ], 'read_all { dir => asc } returns ASC (1..10)' );

    # 1.3 Unpaginated sort => 'asc'
    my @all_sort_asc = $adb->read_all('products', { sort => 'asc' });
    is_deeply( [ map { $_->[0] } @all_sort_asc ], [ 1 .. 10 ], 'read_all { sort => asc } returns ASC (1..10)' );

    # 1.4 Unpaginated sort => { dir => 'asc' }
    my @all_h_asc = $adb->read_all('products', { sort => { dir => 'asc' } });
    is_deeply( [ map { $_->[0] } @all_h_asc ], [ 1 .. 10 ], 'read_all { sort => { dir => asc } } returns ASC (1..10)' );

    # 1.5 Unpaginated sort => { reverse => 1 }
    my @all_rev = $adb->read_all('products', { sort => { reverse => 1 } });
    is_deeply( [ map { $_->[0] } @all_rev ], [ 1 .. 10 ], 'read_all { sort => { reverse => 1 } } returns ASC (1..10)' );

    # 1.6 Pagination default DESC (offset=0, limit=4 -> 10, 9, 8, 7)
    my ( $tot1, @page1 ) = $adb->read_all('products', 0, 4);
    is( $tot1, 10, 'Paginated total count is 10' );
    is_deeply( [ map { $_->[0] } @page1 ], [ 10, 9, 8, 7 ], 'Page 1 default DESC is [10, 9, 8, 7]' );

    # 1.7 Pagination Page 2 default DESC (offset=4, limit=4 -> 6, 5, 4, 3)
    my ( undef, @page2 ) = $adb->read_all('products', 4, 4);
    is_deeply( [ map { $_->[0] } @page2 ], [ 6, 5, 4, 3 ], 'Page 2 default DESC is [6, 5, 4, 3]' );

    # 1.8 Pagination with explicit dir => 'asc' (offset=0, limit=4 -> 1, 2, 3, 4)
    my ( undef, @page1_asc ) = $adb->read_all('products', 0, 4, dir => 'asc');
    is_deeply( [ map { $_->[0] } @page1_asc ], [ 1, 2, 3, 4 ], 'Page 1 dir => asc is [1, 2, 3, 4]' );
};

# ============================================================================
# SUBTEST 2: table_keys Default DESC and dir => 'asc'
# ============================================================================
subtest '2. table_keys default DESC and dir => asc' => sub {
    plan tests => 3;

    my @keys_desc = $adb->table_keys('products');
    is_deeply( \@keys_desc, [ reverse 1 .. 10 ], 'table_keys defaults to DESC (10..1)' );

    my @keys_asc = $adb->table_keys('products', 'asc');
    is_deeply( \@keys_asc, [ 1 .. 10 ], 'table_keys with asc arg returns 1..10' );

    my @keys_h_asc = $adb->table_keys('products', { dir => 'asc' });
    is_deeply( \@keys_h_asc, [ 1 .. 10 ], 'table_keys with { dir => asc } returns 1..10' );
};

# ============================================================================
# SUBTEST 3: field_fetch Default DESC and dir => 'asc'
# ============================================================================
subtest '3. field_fetch default DESC and dir => asc' => sub {
    plan tests => 4;

    # Evens: 2, 4, 6, 8, 10
    # 3.1 Paged default DESC (offset=0, limit=3 -> 10, 8, 6)
    my ( $tot, @even_desc ) = $adb->field_fetch('products', 2, 'even', 0, 3);
    is( $tot, 5, 'field_fetch even total is 5' );
    is_deeply( [ map { $_->[0] } @even_desc ], [ 10, 8, 6 ], 'field_fetch default DESC paged is [10, 8, 6]' );

    # 3.2 Paged explicit dir => 'asc' (offset=0, limit=3 -> 2, 4, 6)
    my ( undef, @even_asc ) = $adb->field_fetch('products', 2, 'even', 0, 3, dir => 'asc');
    is_deeply( [ map { $_->[0] } @even_asc ], [ 2, 4, 6 ], 'field_fetch dir => asc paged is [2, 4, 6]' );

    # 3.3 Unpaginated default DESC
    my @even_all = $adb->field_fetch('products', 2, 'even');
    is_deeply( [ map { $_->[0] } @even_all ], [ 10, 8, 6, 4, 2 ], 'field_fetch unpaginated default is DESC [10, 8, 6, 4, 2]' );
};

# ============================================================================
# SUBTEST 4: Unindexed Table (no_index) Parity with Indexed Table
# ============================================================================
subtest '4. Unindexed table parity' => sub {
    plan tests => 3;

    # 4.1 Unpaginated default DESC
    my @un_all = $adb->read_all('unindexed');
    is_deeply( [ map { $_->[0] } @un_all ], [ reverse 1 .. 10 ], 'Unindexed read_all defaults to DESC (10..1)' );

    # 4.2 Paginated default DESC
    my ( $tot, @un_p1 ) = $adb->read_all('unindexed', 0, 4);
    is_deeply( [ map { $_->[0] } @un_p1 ], [ 10, 9, 8, 7 ], 'Unindexed page 1 default DESC is [10, 9, 8, 7]' );

    # 4.3 Paginated dir => 'asc'
    my ( undef, @un_asc ) = $adb->read_all('unindexed', 0, 4, dir => 'asc');
    is_deeply( [ map { $_->[0] } @un_asc ], [ 1, 2, 3, 4 ], 'Unindexed page 1 dir => asc is [1, 2, 3, 4]' );
};

done_testing();
