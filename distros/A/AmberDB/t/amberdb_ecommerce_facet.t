#!/usr/bin/perl

# t/amberdb/amberdb_ecommerce_facet.t - End-to-end E-Commerce Faceted Search & Navigation Test

use 5.016000;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0 }
);

# 1. Setup Dimension Tables (RDBM)
$adb->table_attr( 'catalog_category', {
    record_index => 1,
    blocks       => [
        { id => "id",   type => "auto_id" },
        { id => "name", type => "text" },
    ]
} );
$adb->insert_id( 'catalog_category', 1, 'Roman' );
$adb->insert_id( 'catalog_category', 2, 'Tarih' );
$adb->insert_id( 'catalog_category', 3, 'Bilim Kurgu' );

$adb->table_attr( 'catalog_producer', {
    record_index => 1,
    blocks       => [
        { id => "id",   type => "auto_id" },
        { id => "name", type => "text" },
    ]
} );
$adb->insert_id( 'catalog_producer', 10, 'Can Yayınları' );
$adb->insert_id( 'catalog_producer', 20, 'İş Bankası Kültür Yayınları' );
$adb->insert_id( 'catalog_producer', 30, 'İthaki Yayınları' );

$adb->table_attr( 'catalog_contributor', {
    record_index => 1,
    blocks       => [
        { id => "id",   type => "auto_id" },
        { id => "name", type => "text" },
    ]
} );
$adb->insert_id( 'catalog_contributor', 100, 'Mustafa Kemal Atatürk' );
$adb->insert_id( 'catalog_contributor', 200, 'Franz Kafka' );
$adb->insert_id( 'catalog_contributor', 300, 'Frank Herbert' );
$adb->insert_id( 'catalog_contributor', 400, 'Dostoyevski' );

# 2. Setup Main Product Table with Facets, Search, Junk and RDBM
$adb->table_attr( 'catalog_product', {
    record_index => 1,
    use_junk     => 1,
    use_facet    => 1,
    junk_rules   => [ [ 6, "ne", 1 ] ],     # status != 1 -> junk
    facet_rules  => [ [ 6, "eq", 1 ] ],     # status == 1 -> active in facet
    search_block => [ 4 ],                  # Search on title
    match_block  => [ 1, 2, 3, 5, 6 ],
    facet_block  => [
        { blk => 1, id => 'cat',    label => 'Kategori',  table => 'catalog_category',    name_idx => 1 },
        { blk => 2, id => 'pub',    label => 'Yayınevi',  table => 'catalog_producer',    name_idx => 1 },
        { blk => 3, id => 'auth',   label => 'Yazar',     table => 'catalog_contributor', name_idx => 1 },
        { blk => 5, id => 'format', label => 'Kapak',     rdbm  => '' }, # .unq based
    ],
    blocks       => [
        { id => "id",     type => "auto_id" },                                  # 0
        { id => "cat",    type => "text", rdbm => "catalog_category;1" },       # 1 (Category)
        { id => "pub",    type => "text", rdbm => "catalog_producer;1" },       # 2 (Publisher)
        { id => "auth",   type => "text", rdbm => "catalog_contributor;1" },    # 3 (Author)
        { id => "title",  type => "text" },                                     # 4 (Title)
        { id => "format", type => "text" },                                     # 5 (Ciltli / Karton)
        { id => "status", type => "option" },                                   # 6 (1:Aktif, 0:Pasif)
        { id => "price",  type => "text" },                                     # 7 (Fiyat)
    ]
} );

# 3. Ingest Test Catalog
# Record: [ id, cat, pub, auth, title, format, status, price ]
my @products = (
    [ 1, 1, 10, 200, 'Dönüşüm',                'Karton', 1, 85.00 ],
    [ 2, 1, 10, 200, 'Dava',                   'Ciltli', 1, 150.00 ],
    [ 3, 1, 20, 400, 'Suç ve Ceza',            'Ciltli', 1, 195.00 ],
    [ 4, 1, 20, 400, 'Karamazov Kardeşler',    'Karton', 1, 220.00 ],
    [ 5, 2, 20, 100, 'Nutuk',                  'Ciltli', 1, 250.00 ],
    [ 6, 2, 20, 100, 'Geometri',               'Karton', 1, 75.00 ],
    [ 7, 3, 30, 300, 'Dune',                   'Ciltli', 1, 280.00 ],
    [ 8, 3, 30, 300, 'Dune Mesihi',            'Karton', 1, 160.00 ],
    [ 9, 3, 30, 300, 'Dune Çocukları (Pasif)', 'Karton', 0, 140.00 ], # JUNK / Inactive
);

$adb->insert_list( 'catalog_product', @products );

# ---------------------------------------------------------------------------
subtest '1. Initial Unfiltered Facet Menu & Label Resolution' => sub {
    plan tests => 8;

    my $menu = $adb->facet_menu(
        'catalog_product',
        {}, # No filter selected
        $adb->table_attr('catalog_product', 'facet_block'),
        { sort => 'count' }
    );

    ok( $menu, "Facet menu generated successfully" );
    is( $menu->{count}, 8, "Total active products count is 8 (junk item excluded)" );
    is( scalar( @{ $menu->{groups} } ), 4, "4 facet groups returned" );

    # Check Category Group (blk 1)
    my ($cat_group) = grep { $_->{blk} == 1 } @{ $menu->{groups} };
    ok( $cat_group, "Category facet group exists" );
    is( $cat_group->{name}, 'Kategori', "Category label correct" );

    # Roman (id: 1) has 4 products (IDs 1, 2, 3, 4)
    my ($roman_item) = grep { $_->{label} eq 'Roman' } @{ $cat_group->{records} };
    ok( $roman_item, "RDBM resolved 'Roman' name" );
    is( $roman_item->{count}, 4, "'Roman' category count is 4" );

    # Dune author Frank Herbert (id: 300) has 2 active products (ID 7, 8; ID 9 is passive)
    my ($auth_group) = grep { $_->{blk} == 3 } @{ $menu->{groups} };
    my ($herbert_item) = grep { $_->{label} eq 'Frank Herbert' } @{ $auth_group->{records} };
    is( $herbert_item->{count}, 2, "Frank Herbert count is 2 (inactive 3rd book excluded)" );
};

# ---------------------------------------------------------------------------
subtest '2. Single Dimension Filtering & Cross-Filter Counts (Disjunctive Faceting)' => sub {
    plan tests => 6;

    # Filter: Category = Roman (cat: 1)
    my $menu = $adb->facet_menu(
        'catalog_product',
        { 1 => 1 }, # Category = 1 (Roman)
        $adb->table_attr('catalog_product', 'facet_block'),
        { sort => 'count' }
    );

    is( $menu->{count}, 4, "Filtered result has 4 Roman books" );
    is_deeply( [ sort { $a <=> $b } @{ $menu->{ids} } ], [ 1, 2, 3, 4 ], "Correct product IDs returned" );

    # Category menu itself (blk 1) should still display other category counts under disjunctive faceting!
    my ($cat_group) = grep { $_->{blk} == 1 } @{ $menu->{groups} };
    my ($tarih_item) = grep { $_->{label} eq 'Tarih' } @{ $cat_group->{records} };
    is( $tarih_item->{count}, 2, "Disjunctive facet preserves other categories count (Tarih: 2)" );

    # Publisher menu (blk 2) should ONLY count publishers within Roman!
    my ($pub_group) = grep { $_->{blk} == 2 } @{ $menu->{groups} };
    my ($can_pub)    = grep { $_->{label} eq 'Can Yayınları' } @{ $pub_group->{records} };
    my ($is_pub)     = grep { $_->{label} eq 'İş Bankası Kültür Yayınları' } @{ $pub_group->{records} };
    my ($ithaki_pub) = grep { $_->{label} eq 'İthaki Yayınları' } @{ $pub_group->{records} };

    is( $can_pub->{count}, 2, "Can Yayınları has 2 Roman books" );
    is( $is_pub->{count}, 2, "İş Bankası has 2 Roman books" );
    ok( !$ithaki_pub, "İthaki Yayınları has 0 Roman books (correctly omitted)" );
};

# ---------------------------------------------------------------------------
subtest '3. Multi-Dimension Filtering (Category + Publisher + Format)' => sub {
    plan tests => 4;

    # Filter: Category = Roman (1) AND Publisher = Can Yayınları (10) AND Format = Ciltli (in .unq format is resolved)
    my $menu = $adb->facet_menu(
        'catalog_product',
        { 1 => 1, 2 => 10, 5 => 'Ciltli' },
        $adb->table_attr('catalog_product', 'facet_block'),
        { sort => 'count' }
    );

    is( $menu->{count}, 1, "Only 1 book matches all 3 criteria" );
    is_deeply( $menu->{ids}, [2], "Product ID 2 ('Dava' by Kafka) returned" );

    my ($auth_group) = grep { $_->{blk} == 3 } @{ $menu->{groups} };
    my ($kafka_item) = grep { $_->{label} eq 'Franz Kafka' } @{ $auth_group->{records} };
    is( $kafka_item->{count}, 1, "Author Kafka has 1 matching item" );
    is( scalar( @{ $auth_group->{records} } ), 1, "Only Kafka is in Author facet" );
};

# ---------------------------------------------------------------------------
subtest '4. Faceted Navigation over Full-Text Search Results (base_ids)' => sub {
    plan tests => 4;

    # Search keyword "Dune" (should match IDs 7, 8; ID 9 is junk)
    my @hit_ids = $adb->search_table( 'catalog_product', 'Dune', keys_only => 1, jnktype => 'A' );
    is( scalar(@hit_ids), 2, "Search found 2 active Dune books" );

    # Apply facet menu over search hits
    my $menu = $adb->facet_menu(
        'catalog_product',
        {},
        $adb->table_attr('catalog_product', 'facet_block'),
        { base_ids => \@hit_ids }
    );

    is( $menu->{count}, 2, "Facet menu restricted to 2 search hits" );
    my ($cat_group) = grep { $_->{blk} == 1 } @{ $menu->{groups} };
    is( scalar( @{ $cat_group->{records} } ), 1, "Only Bilim Kurgu category present in search facets" );
    is( $cat_group->{records}->[0]->{label}, 'Bilim Kurgu', "Category is Bilim Kurgu" );
};

# ---------------------------------------------------------------------------
subtest '5. Dynamic Price Range (Min/Max Slider) & Facet Integration' => sub {
    plan tests => 5;

    # Scenario: User selects Price range [100.00 TL - 200.00 TL]
    # In catalog_product, prices are:
    # 1: 85.00  (Roman, Can, Kafka) -> OUT (< 100)
    # 2: 150.00 (Roman, Can, Kafka) -> IN
    # 3: 195.00 (Roman, Is Bankasi, Dostoyevski) -> IN
    # 4: 220.00 (Roman, Is Bankasi, Dostoyevski) -> OUT (> 200)
    # 5: 250.00 (Tarih, Is Bankasi, Ataturk) -> OUT (> 200)
    # 6: 75.00  (Tarih, Is Bankasi, Ataturk) -> OUT (< 100)
    # 7: 280.00 (Bilim Kurgu, Ithaki, Herbert) -> OUT (> 200)
    # 8: 160.00 (Bilim Kurgu, Ithaki, Herbert) -> IN

    my $min_price = 100.00;
    my $max_price = 200.00;

    # Read active products price column to get matching IDs
    my ( undef, @all_active_ids ) = $adb->index_get( $adb->table_path('catalog_product') . ".inx", "A:keys" );
    my @price_matched_ids;
    for my $id (@all_active_ids) {
        my @row = $adb->read_id( 'catalog_product', $id );
        my $price = $row[7] + 0;
        if ( $price >= $min_price && $price <= $max_price ) {
            push @price_matched_ids, $id;
        }
    }

    is_deeply( [ sort { $a <=> $b } @price_matched_ids ], [ 2, 3, 8 ], "Price range [100 - 200] matches IDs 2, 3, 8" );

    # Generate Facet menu constrained by the dynamic price slider (base_ids)
    my $menu = $adb->facet_menu(
        'catalog_product',
        {},
        $adb->table_attr('catalog_product', 'facet_block'),
        { base_ids => \@price_matched_ids }
    );

    is( $menu->{count}, 3, "Facet menu restricted to 3 price-matched products" );

    # Category counts within price range [100 - 200]
    my ($cat_group) = grep { $_->{blk} == 1 } @{ $menu->{groups} };
    my ($roman_item) = grep { $_->{label} eq 'Roman' } @{ $cat_group->{records} };
    my ($scifi_item) = grep { $_->{label} eq 'Bilim Kurgu' } @{ $cat_group->{records} };

    is( $roman_item->{count}, 2, "Roman has 2 books in price range [100-200]" );
    is( $scifi_item->{count}, 1, "Bilim Kurgu has 1 book in price range [100-200]" );

    # Tarih has 0 books between 100-200 (75 and 250), so it should not appear
    my ($tarih_item) = grep { $_->{label} eq 'Tarih' } @{ $cat_group->{records} };
    ok( !$tarih_item, "Tarih category has 0 items in [100-200] range and is omitted" );
};

done_testing();
