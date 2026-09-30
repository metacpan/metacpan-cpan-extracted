#!/usr/bin/perl

# t/amberdb_suggest.t - Tests for autocomplete / suggest index (.ajw, .ajn)

use 5.016000;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';
use AmberDB;

binmode( Test::More->builder->$_, ":utf8" ) for qw(output failure_output todo_output);

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0 }
);

$adb->table_attr( 'catalog_product', {
    record_index  => 1,
    suggest_block => [ 1, 2, 3 ],
    suggest_join  => [ [ 2, 3 ] ],
} );

subtest '1. Insertion & Automatic Suggest Index Generation (.ajw, .ajn)' => sub {
    plan tests => 2;

    my @records = (
        [ 1, 'Can Yayınları', 'Orhan Pamuk', 'Masumiyet Müzesi' ],
        [ 2, 'Can Yayınları', 'Orhan Pamuk', 'Kara Kitap' ],
        [ 3, 'İletişim Yayınları', 'Orhan Kemal', 'Bereketli Topraklar Üzerinde' ],
        [ 4, 'Can Yayınları', 'Orhan Hançerlioğlu', 'Ali' ],
        [ 5, 'Can Yayınları', 'Jose Mauro de Vasconcelos', 'Şeker Portakalı' ],
        [ 6, 'Doğan Kitap', 'Maruf, Sultan', 'E-Ticaret Stratejileri' ],
        [ 7, 'Doğan Kitap', 'Maruf Çetin, Sultan Çetin', 'Modern Perl' ],
    );

    $adb->insert_list( 'catalog_product', @records );

    my $table_path = $adb->table_path('catalog_product');
    ok( -e "$table_path.ajw", ".ajw word prefix index created" );
    ok( -e "$table_path.ajn", ".ajn next word transition index created" );
};

subtest '2. Single Word Prefix Search (.ajw)' => sub {
    plan tests => 4;

    # "or" prefix
    my @sug_or = $adb->suggest_table( 'catalog_product', 'or' );
    ok( ( grep { $_ eq 'orhan' } @sug_or ), 'Found orhan for prefix "or"' );

    # "mas" prefix
    my @sug_mas = $adb->suggest_table( 'catalog_product', 'mas' );
    ok( ( grep { $_ eq 'masumiyet' } @sug_mas ), 'Found masumiyet for prefix "mas"' );

    # ASCII tolerance: "sek" finds "şeker"
    my @sug_sek = $adb->suggest_table( 'catalog_product', 'sek' );
    ok( ( grep { $_ eq 'şeker' } @sug_sek ), 'Found şeker for ascii prefix "sek"' );

    # Turkish prefix: "şek" finds "şeker"
    my @sug_turk = $adb->suggest_table( 'catalog_product', 'şek' );
    ok( ( grep { $_ eq 'şeker' } @sug_turk ), 'Found şeker for turkish prefix "şek"' );
};

subtest '3. Space Transition & Next Word Süzgeç (.ajn)' => sub {
    plan tests => 5;

    # "orhan " -> shows top next words (pamuk, kemal, hançerlioğlu)
    my @sug_space = $adb->suggest_table( 'catalog_product', 'orhan ' );
    ok( ( grep { /pamuk/ } @sug_space ), 'Found pamuk after "orhan "' );
    ok( ( grep { /kemal/ } @sug_space ), 'Found kemal after "orhan "' );

    # "orhan p" -> filters for pamuk
    my @sug_p = $adb->suggest_table( 'catalog_product', 'orhan p' );
    is( $sug_p[0], 'orhan pamuk', 'Matched "orhan pamuk" for "orhan p"' );

    # "orhan h" -> filters for hançerlioğlu (Long-tail preserved!)
    my @sug_h = $adb->suggest_table( 'catalog_product', 'orhan h' );
    is( $sug_h[0], 'orhan hançerlioğlu', 'Matched "orhan hançerlioğlu" for "orhan h"' );

    # "orhan pamuk m" -> chained transition to masumiyet
    my @sug_chained = $adb->suggest_table( 'catalog_product', 'orhan pamuk m' );
    is( $sug_chained[0], 'orhan pamuk masumiyet', 'Matched "orhan pamuk masumiyet" for "orhan pamuk m"' );
};

subtest '4. Multi-value Author Field (Virgüllü Liste)' => sub {
    plan tests => 4;

    # Single-word multi authors: "maruf e" -> pairs Author 1 with Title
    my @sug_maruf = $adb->suggest_table( 'catalog_product', 'maruf e' );
    is( $sug_maruf[0], 'maruf eticaret', 'Author 1 + Title matched ("maruf eticaret")' );

    # Single-word multi authors: "sultan e" -> pairs Author 2 with Title
    my @sug_sultan = $adb->suggest_table( 'catalog_product', 'sultan e' );
    is( $sug_sultan[0], 'sultan eticaret', 'Author 2 + Title matched ("sultan eticaret")' );

    # Multi-word multi authors: "maruf cetin m"
    my @sug_cetin1 = $adb->suggest_table( 'catalog_product', 'maruf cetin m' );
    is( $sug_cetin1[0], 'maruf cetin modern', 'Multi-word Author 1 + Title matched ("maruf cetin modern")' );

    # Multi-word multi authors: "sultan cetin m"
    my @sug_cetin2 = $adb->suggest_table( 'catalog_product', 'sultan cetin m' );
    is( $sug_cetin2[0], 'sultan cetin modern', 'Multi-word Author 2 + Title matched ("sultan cetin modern")' );
};

subtest '5. Rebuild via reindex_suggest & Tools::Index' => sub {
    plan tests => 3;

    require AmberDB::Tools;
    my $tools = AmberDB::Tools->new($adb);
    my $reindex_ok = $tools->set_index('catalog_product');
    ok( $reindex_ok, 'reindex succeeded' );

    my @sug_after = $adb->suggest_table( 'catalog_product', 'orhan p' );
    is( $sug_after[0], 'orhan pamuk', 'Suggest works identically after reindex' );

    my @sug_h_after = $adb->suggest_table( 'catalog_product', 'orhan h' );
    is( $sug_h_after[0], 'orhan hançerlioğlu', 'Long-tail hançerlioğlu preserved after reindex' );
};

subtest '6. Ramdisk Tier 1 (R1) Index-Only Suggestion Reading' => sub {
    plan tests => 4;

    local $ENV{AMBERDB_TEST_RAMDISK} = 1;
    my $mock_mount = tempdir( CLEANUP => 1 );
    my $ram_root   = File::Spec->catdir( $mock_mount, 'amberdb_suggest_ram' );
    make_path($ram_root);

    my $adb_ram = AmberDB->new(
        database => 'suggest_ram',
        path     => {
            dbase_dir   => $tmpdir,
            ramdisk_dir => $ram_root,
        },
        cfg      => {
            simple      => 0,
            use_ramdisk => 1,
        }
    );

    $adb_ram->table_attr( 'books_ram', {
        record_index  => 1,
        use_ramdisk   => 1,
        suggest_block => [ 1, 2, 3 ],
        suggest_join  => [ [ 2, 3 ] ],
    } );

    $adb_ram->insert_list( 'books_ram',
        [ 1, 'YKY', 'Yaşar Kemal', 'İnce Memed' ],
        [ 2, 'Can', 'Sabahattin Ali', 'Kürk Mantolu Madonna' ],
    );

    my $ram_path = $adb_ram->ramdisk_path('books_ram');
    ok( -e "$ram_path.ajw", 'Tier 1 .ajw exists on RAM-disk' );
    ok( -e "$ram_path.ajn", 'Tier 1 .ajn exists on RAM-disk' );

    my @sug_ram = $adb_ram->suggest_table( 'books_ram', 'yas' );
    ok( ( grep { /yaşar/ } @sug_ram ), 'Found yaşar from RAM-disk .ajw in Tier 1' );

    my @sug_ram_trans = $adb_ram->suggest_table( 'books_ram', 'sabahattin ali k' );
    is( $sug_ram_trans[0], 'sabahattin ali kürk', 'Matched kürk from RAM-disk .ajn in Tier 1' );
};

done_testing();
