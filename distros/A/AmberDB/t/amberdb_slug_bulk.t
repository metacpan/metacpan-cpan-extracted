#!/usr/bin/perl

# t/amberdb_slug_bulk.t - Dedicated tests for bulk slug_add, slug_modify, and slug_del

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0 }
);

$adb->table_attr( 'articles', {
    record_index => 1,
    slug_block   => [ 1 ],
} );

subtest '1. Bulk insert with slug generation & collision resolution' => sub {
    plan tests => 6;

    my @records = (
        [ 1, 'Hello World', 'Tech' ],
        [ 2, 'Hello World', 'Tech' ],
        [ 3, 'Unique Title', 'General' ],
    );

    $adb->insert_list( 'articles', @records );

    my $slugs = $adb->get_slug( 'articles', 0, 1, 2, 3 );
    is( $slugs->{1}, 'hello-world', 'First record gets clean slug' );
    is( $slugs->{2}, 'hello-world-2', 'Duplicate gets collision suffix with ID' );
    is( $slugs->{3}, 'unique-title', 'Unique record gets clean slug' );

    my $rev = $adb->get_slug( 'articles', 1, 'hello-world', 'hello-world-2', 'unique-title' );
    is( $rev->{'hello-world'}, 1, 'Reverse lookup 1' );
    is( $rev->{'hello-world-2'}, 2, 'Reverse lookup 2' );
    is( $rev->{'unique-title'}, 3, 'Reverse lookup 3' );
};

subtest '2. Bulk modify with slug updates' => sub {
    plan tests => 6;

    # Record 1 title changes, record 2 title does not change (category changes), record 3 title changes
    my @mod_records = (
        [ 1, 'Hello Universe', 'Tech' ],
        [ 2, 'Hello World', 'Science' ],
        [ 3, 'Updated Title', 'General' ],
    );

    $adb->update_list( 'articles', @mod_records );

    my $slugs = $adb->get_slug( 'articles', 0, 1, 2, 3 );
    is( $slugs->{1}, 'hello-universe', 'Record 1 updated to new slug' );
    is( $slugs->{2}, 'hello-world-2', 'Record 2 unchanged slug preserved' );
    is( $slugs->{3}, 'updated-title', 'Record 3 updated to new slug' );

    my $old_rev = $adb->get_slug( 'articles', 1, 'hello-world', 'unique-title' );
    ok( !defined $old_rev->{'hello-world'}, 'Old record 1 slug cleaned up' );
    ok( !defined $old_rev->{'unique-title'}, 'Old record 3 slug cleaned up' );

    my $new_rev = $adb->get_slug( 'articles', 1, 'hello-universe' );
    is( $new_rev->{'hello-universe'}, 1, 'New record 1 reverse lookup works' );
};

subtest '3. Bulk delete with slug removal' => sub {
    plan tests => 6;

    $adb->delete_list( 'articles', 1, 2 );

    my $slugs = $adb->get_slug( 'articles', 0, 1, 2, 3 );
    ok( !defined $slugs->{1}, 'Deleted record 1 slug is gone' );
    ok( !defined $slugs->{2}, 'Deleted record 2 slug is gone' );
    is( $slugs->{3}, 'updated-title', 'Remaining record 3 slug still present' );

    my $rev = $adb->get_slug( 'articles', 1, 'hello-universe', 'hello-world-2', 'updated-title' );
    ok( !defined $rev->{'hello-universe'}, 'Reverse lookup for deleted 1 is gone' );
    ok( !defined $rev->{'hello-world-2'}, 'Reverse lookup for deleted 2 is gone' );
    is( $rev->{'updated-title'}, 3, 'Reverse lookup for remaining 3 still works' );
};

subtest '4. Direct API calls: slug_add, slug_modify, slug_del' => sub {
    plan tests => 5;

    my $tinfo = $adb->table_info('articles');
    my $tpath = $adb->table_path('articles');

    # Direct slug_add
    $adb->slug_add( $tpath, $tinfo, 'articles', [ [ 10, 'Direct Slug', 'Cat' ] ] );
    my $s10 = $adb->get_slug( 'articles', 0, 10 );
    is( $s10->{10}, 'direct-slug', 'Direct slug_add created slug' );

    # Direct slug_modify
    my $pairs = [
        [ 10, [ 10, 'Direct Slug', 'Cat' ], [ 10, 'Direct Modified', 'Cat' ] ]
    ];
    $adb->slug_modify( $tpath, $tinfo, 'articles', $pairs );
    my $s10_mod = $adb->get_slug( 'articles', 0, 10 );
    is( $s10_mod->{10}, 'direct-modified', 'Direct slug_modify updated slug' );

    my $old_check = $adb->get_slug( 'articles', 1, 'direct-slug' );
    ok( !defined $old_check->{'direct-slug'}, 'Direct slug_modify removed old slug' );

    # Direct slug_del
    $adb->slug_del( $tpath, $tinfo, 'articles', [ 10 ] );
    my $s10_del = $adb->get_slug( 'articles', 0, 10 );
    ok( !defined $s10_del->{10}, 'Direct slug_del removed slug' );
    my $del_check = $adb->get_slug( 'articles', 1, 'direct-modified' );
    ok( !defined $del_check->{'direct-modified'}, 'Direct slug_del removed reverse mapping' );
};

done_testing();
