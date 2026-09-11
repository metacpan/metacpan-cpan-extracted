#!/usr/bin/perl

# t/amberdb-locale_09_gb.t - Tests for AmberDB Global Base (gb) Multilingual Locale

use 5.016000;
use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use File::Temp qw(tempdir);

use_ok('AmberDB::Locale') or BAIL_OUT('Cannot load AmberDB::Locale');
use_ok('AmberDB') or BAIL_OUT('Cannot load AmberDB');

# ============================================================
# 1. Constructor and Aliases
# ============================================================
subtest '1. Constructor and Aliases' => sub {
    plan tests => 7;

    # Default constructor without arguments must return 'gb'
    my $def = AmberDB::Locale->new();
    is( $def->language, 'gb', 'Default constructor resolves to gb' );

    # Explicit 'gb'
    my $gb = AmberDB::Locale->new( language => 'gb' );
    is( $gb->language, 'gb', 'Explicit language => gb resolves to gb' );

    # Alias 'global'
    my $global = AmberDB::Locale->new( language => 'global' );
    is( $global->language, 'gb', 'Alias language => global resolves to gb' );

    # Alias 'gl'
    my $gl = AmberDB::Locale->new( language => 'gl' );
    is( $gl->language, 'gb', 'Alias language => gl resolves to gb' );

    # Alias 'universal'
    my $uni = AmberDB::Locale->new( language => 'universal' );
    is( $uni->language, 'gb', 'Alias language => universal resolves to gb' );

    # Positional string
    my $pos = AmberDB::Locale->new('gb');
    is( $pos->language, 'gb', 'Positional string new("gb") resolves to gb' );

    # Alias 'en_gb'
    my $en_gb = AmberDB::Locale->new( language => 'en_gb' );
    is( $en_gb->language, 'gb', 'Alias language => en_gb resolves to gb' );
};

# ============================================================
# 2. Multilingual Alphabet Character Class (alphabet_chars)
# ============================================================
subtest '2. Multilingual Alphabet Preservation in normalize' => sub {
    plan tests => 4;

    my $loc = AmberDB::Locale->new('gb');

    # Turkish characters: Çiğdem Şafak ışık -> accent normalization turns to Cigdem Safak isik
    is( $loc->normalize("Çiğdem Şafak ışık Öğretmen"), "Cigdem Safak isik Ogretmen", 'Turkish letters normalized correctly' );

    # German: Mädchen läuft über die Straße -> Madchen lauft uber die Strasse
    is( $loc->normalize("Mädchen läuft über die Straße"), "Madchen lauft uber die Strasse", 'German umlauts and ß normalized' );

    # French & Spanish
    is( $loc->normalize("café crème cœur garçon mañana"), "cafe creme coeur garcon manana", 'French & Spanish normalized' );

    # HTML tags stripped and characters sanitized
    is( $loc->normalize("<b>café</b> &amp; <i>crème</i>"), "cafe & creme", 'HTML tags stripped and entities preserved/decoded' );
};

# ============================================================
# 3. Canonical Accent Normalization (normalize)
# ============================================================
subtest '3. Canonical Accent Normalization (normalize)' => sub {
    plan tests => 6;

    my $loc = AmberDB::Locale->new('gb');

    # French
    is( $loc->normalize("café"), "cafe", 'normalize: café -> cafe' );
    is( $loc->normalize("HÔTEL"), "HOTEL", 'normalize: HÔTEL -> HOTEL' );

    # German
    is( $loc->normalize("München"), "Munchen", 'normalize: München -> Munchen' );
    is( $loc->normalize("Straße"), "Strasse", 'normalize: Straße -> Strasse' );

    # Turkish
    is( $loc->normalize("ışık"), "isik", 'normalize: ışık -> isik' );

    # Nordic
    is( $loc->normalize("smørrebrød"), "smorrebrod", 'normalize: smørrebrød -> smorrebrod' );
};

# ============================================================
# 4. Lossless ASCII Transliteration (to_ascii / slug)
# ============================================================
subtest '4. Lossless ASCII Transliteration (to_ascii)' => sub {
    plan tests => 8;

    my $loc = AmberDB::Locale->new('gb');

    is( $loc->to_ascii("Straße"), "Strasse", 'to_ascii: ß -> ss' );
    is( $loc->to_ascii("Straße", 1), "strasse", 'to_ascii slug: Straße -> strasse' );
    is( $loc->to_ascii("bærum"), "baerum", 'to_ascii: æ -> ae' );
    is( $loc->to_ascii("cœur"), "coeur", 'to_ascii: œ -> oe' );
    is( $loc->to_ascii("Kraków"), "Krakow", 'to_ascii: ó -> o' );
    is( $loc->to_ascii("Łódź"), "Lodz", 'to_ascii: Ł/ó/ź -> Lodz' );
    is( $loc->to_ascii("smør"), "smor", 'to_ascii: ø -> o' );
    is( $loc->to_ascii("ışık"), "isik", 'to_ascii: ı/ş -> isik' );
};

# ============================================================
# 5. Multilingual Search Regex (search_pattern & search_regex)
# ============================================================
subtest '5. Multilingual Search Regex Pattern' => sub {
    plan tests => 5;

    my $loc = AmberDB::Locale->new('gb');

    # Searching 'cafe' matches both 'cafe' and 'café'
    my $pat_c = $loc->search_pattern('cafe');
    ok( $loc->search_regex('café', $pat_c), 'search_regex: cafe matches café' );
    ok( $loc->search_regex('CAFE', $pat_c), 'search_regex: cafe matches CAFE' );

    # Searching 'munchen' matches 'münchen'
    my $pat_m = $loc->search_pattern('munchen');
    ok( $loc->search_regex('München', $pat_m), 'search_regex: munchen matches München' );

    # Searching 'seker' matches 'şeker'
    my $pat_s = $loc->search_pattern('seker');
    ok( $loc->search_regex('şeker', $pat_s), 'search_regex: seker matches şeker' );

    # Searching 'isik' matches 'ışık'
    my $pat_i = $loc->search_pattern('isik');
    ok( $loc->search_regex('ışık', $pat_i), 'search_regex: isik matches ışık' );
};

# ============================================================
# 6. AmberDB Engine Integration: Default Language is 'gb'
# ============================================================
subtest '6. AmberDB Engine Integration with Default gb Locale' => sub {
    plan tests => 8;

    my $tmpdir = tempdir( CLEANUP => 1 );
    my $adb = AmberDB->new(
        path => { dbase_dir => $tmpdir },
    );

    is( $adb->language, 'gb', 'AmberDB instance initializes with gb language by default' );
    is( $adb->config('language'), 'gb', 'AmberDB config("language") defaults to gb' );

    my $tbl = 'global_catalog';
    $adb->table_attr( $tbl, {
        record_index => 1,
        search_block => [ 2, 3 ], # Title, Desc
    });

    # Insert items in multiple languages
    $adb->insert_id( $tbl, 1, 'SKU-1', 'French Café Roastery', 'Artisan espresso blend' );
    $adb->insert_id( $tbl, 2, 'SKU-2', 'München Weissbier Glass', 'Traditionelles Glas aus Bayern' );
    $adb->insert_id( $tbl, 3, 'SKU-3', 'Türk Lokumu Şekerleme', 'Geleneksel antep fıstıklı tatlı' );

    # Search unaccented 'cafe' -> should find 'French Café Roastery' (ID 1)
    my @res_cafe = $adb->search_table( $tbl, 'cafe' );
    is( scalar @res_cafe, 1, 'search_table finds 1 record for "cafe"' );
    is( $res_cafe[0]->[0], 1, 'search_table: "cafe" query matches "Café" (ID 1)' );

    # Search unaccented 'munchen' -> should find 'München' (ID 2)
    my @res_munchen = $adb->search_table( $tbl, 'munchen' );
    is( scalar @res_munchen, 1, 'search_table finds 1 record for "munchen"' );
    is( $res_munchen[0]->[0], 2, 'search_table: "munchen" query matches "München" (ID 2)' );

    # Search unaccented 'sekerleme' -> should find 'Şekerleme' (ID 3)
    my @res_seker = $adb->search_table( $tbl, 'sekerleme' );
    is( scalar @res_seker, 1, 'search_table finds 1 record for "sekerleme"' );
    is( $res_seker[0]->[0], 3, 'search_table: "sekerleme" query matches "Şekerleme" (ID 3)' );
};

done_testing();
