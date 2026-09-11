#!/usr/bin/perl

# t/amberdb/amberdb_facet_columnar.t - Tests for Columnar Facet, .unq Dictionary Prefixes, and Dynamic Scoping (base_ids)

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0 }
);

# Schema definition via official table_attr API
$adb->table_attr( 'catalog_product', {
    record_index => 1,
    match_block  => [ 1, 2, 3 ],
    facet_block  => [
        { blk => 1, id => 'cat',   label => 'Kategori' },
        { blk => 2, id => 'brand', label => 'Marka' },
        { blk => 3, id => 'color', label => 'Renk' },
    ],
    use_facet    => 1,
    facet_rules  => [ [ 4, 'eq', 1 ] ], # block 4 == 1 means active
} );

# ---------------------------------------------------------------------------
subtest '1. .unq dictionary prefix architecture (s: and n:)' => sub {
    plan tests => 6;

    my $table_path = $adb->table_path('catalog_product');
    my $tinfo = $adb->table_info('catalog_product');

    # Convert strings to IDs (write mode via set_fieldlist)
    my @ids = $adb->set_fieldlist( 'Elektronik', $table_path, $tinfo, 1 );
    is( scalar @ids, 1, "Generated 1 numeric ID for 'Elektronik'" );
    my $elek_id = $ids[0];
    ok( $elek_id =~ /^\d+$/, "ID is numeric" );

    # Check forward key 1:s:Elektronik
    my $unq_file = "${table_path}.unq";
    my ($stored_id) = $adb->index_get( $unq_file, "1:s:Elektronik", 'raw' );
    is( $stored_id, $elek_id, "1:s:Elektronik maps to numeric ID $elek_id" );

    # Check reverse key 1:n:$elek_id
    my ($stored_name) = $adb->index_get( $unq_file, "1:n:$elek_id", 'raw' );
    is( $stored_name, 'Elektronik', "1:n:$elek_id maps back to 'Elektronik'" );

    # Test reading mode (read mode via get_fieldlist)
    my @read_ids = $adb->get_fieldlist( 'Elektronik', $table_path, $tinfo, 1 );
    is_deeply( \@read_ids, [$elek_id], "get_fieldlist read mode resolves 'Elektronik' to $elek_id" );

    # Idempotent write: same string gets same ID
    my @ids2 = $adb->set_fieldlist( 'Elektronik', $table_path, $tinfo, 1 );
    is( $ids2[0], $elek_id, "Idempotent: same string reuses existing ID" );
};

# ---------------------------------------------------------------------------
subtest '2. Columnar .fac files and active-only indexing' => sub {
    plan tests => 6;

    # Record format: [ $rid, $cat, $brand, $color, $status ]
    # Active products ($status == 1)
    $adb->insert_id( 'catalog_product', 101, 'Telefon', 'Apple', 'Siyah', 1 );
    $adb->insert_id( 'catalog_product', 102, 'Telefon', 'Samsung', 'Beyaz', 1 );
    $adb->insert_id( 'catalog_product', 103, 'Bilgisayar', 'Apple', 'Gri', 1 );

    # Inactive product ($status == 0) -> should NOT be indexed in .fac
    $adb->insert_id( 'catalog_product', 104, 'Telefon', 'Apple', 'Mavi', 0 );

    my $table_path = $adb->table_path('catalog_product');

    # Check that unified .fac file exists
    ok( -e "${table_path}.fac", "Unified .fac exists" );

    # Check that inactive record 104 is NOT in .fac
    my ($raw_104) = $adb->index_get( "${table_path}.fac", "1:104", 'raw' );
    ok( !defined $raw_104, "Inactive record 104 is not indexed in .fac" );

    # Check that active record 101 IS in .fac for all configured blocks
    my ($raw_101_b1) = $adb->index_get( "${table_path}.fac", "1:101", 'raw' );
    ok( defined $raw_101_b1 && $raw_101_b1 ne '', "Active record 101 is indexed in 1:101" );
    my ($raw_101_b2) = $adb->index_get( "${table_path}.fac", "2:101", 'raw' );
    ok( defined $raw_101_b2 && $raw_101_b2 ne '', "Active record 101 is indexed in 2:101" );
    my ($raw_101_b3) = $adb->index_get( "${table_path}.fac", "3:101", 'raw' );
    ok( defined $raw_101_b3 && $raw_101_b3 ne '', "Active record 101 is indexed in 3:101" );

    # Verify active ID set contains 101, 102, 103 but not 104
    my ( undef, @acts ) = $adb->index_get( "${table_path}.fac", "active", "ids" );
    is_deeply( [ sort { $a <=> $b } @acts ], [ 101, 102, 103 ], "Active IDs in .fac" );
};

# ---------------------------------------------------------------------------
subtest '3. Dynamic Scope (base_ids) bypassing full scan' => sub {
    plan tests => 3;

    # Test field_fltkeys with scoped base_ids
    # Suppose a search returned only product 101 and 102
    my $scoped_brands = $adb->field_fltkeys(
        'catalog_product',
        {
            target_block => 2,
            base_ids     => [ 101, 102 ],
        }
    );

    is( $scoped_brands->{'Apple'}, 1, "Scoped facet count: Apple = 1" );
    is( $scoped_brands->{'Samsung'}, 1, "Scoped facet count: Samsung = 1" );
    ok( !exists $scoped_brands->{'Dell'}, "Dell not in scope" );
};

# ---------------------------------------------------------------------------
subtest '4. facet_menu generation with selected filters' => sub {
    plan tests => 3;

    my $facet_menu = $adb->facet_menu(
        'catalog_product',
        { 1 => 'Telefon' }, # Filter by Telefon
        $adb->table_info('catalog_product')->{facet_block}
    );

    ok( ref($facet_menu) eq 'HASH', "facet_menu returned hash" );
    ok( exists $facet_menu->{groups_by_blk}, "groups_by_blk exists" );

    my $brand_group = $facet_menu->{groups_by_blk}->{2};
    ok( scalar @$brand_group >= 2, "Brand group contains items for filtered category" );
};

# ---------------------------------------------------------------------------
subtest '5. Facet lifecycle with Junk transitions (Active -> Junk -> Active)' => sub {
    plan tests => 4;

    # Configure table with both use_facet and use_junk
    $adb->table_attr( 'catalog_product', use_junk => 1, junk_rules => [ [ 4, 'ne', 1 ] ] ); # block 4 != 1 -> junk

    my $table_path = $adb->table_path('catalog_product');

    # Initial state: 101 is active (status 1) -> in .fac
    my ($fac_101_init) = $adb->index_get( "${table_path}.fac", "1:101", 'raw' );
    ok( defined $fac_101_init, "Initial: Active 101 is in .fac" );

    # Transition 1: Product 101 becomes out-of-sale (status 0) -> becomes junk -> removed from .fac
    $adb->modify_id( 'catalog_product', 101, 'Telefon', 'Apple', 'Siyah', 0 );
    my ($fac_101_junk) = $adb->index_get( "${table_path}.fac", "1:101", 'raw' );
    ok( !defined $fac_101_junk, "Active -> Junk: 101 was removed from .fac" );

    # Verify 101 is in junk B:keys in .inx
    my ( undef, @jinx_keys ) = $adb->index_get( "$table_path.inx", "B:keys" );
    ok( ( grep { $_ == 101 } @jinx_keys ), "Product 101 is correctly indexed in .inx (B:keys)" );

    # Transition 2: Product 101 becomes in-sale again (status 1) -> restored to active -> restored to .fac
    $adb->modify_id( 'catalog_product', 101, 'Telefon', 'Apple', 'Siyah', 1 );
    my ($fac_101_restored) = $adb->index_get( "${table_path}.fac", "1:101", 'raw' );
    ok( defined $fac_101_restored && $fac_101_restored ne '', "Junk -> Active: 101 was restored to .fac" );
};

done_testing();
