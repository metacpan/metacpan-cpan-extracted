#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';

use AmberDB::Locale;

# ============================================================
# 1. Constructor — Turkish locale
# ============================================================
my $tr = AmberDB::Locale->new( language => 'tr' );
is( $tr->language, 'tr', 'Constructor: language tag stored' );

# ============================================================
# 2. English locale and Global Base (gb) fallback
# ============================================================
my $en = AmberDB::Locale->new( language => 'en' );
is( $en->language, 'en', 'Constructor: English locale' );

# Unknown locale falls back to gb
my $xx;
{
    local $SIG{__WARN__} = sub {};    # suppress fallback warning
    $xx = AmberDB::Locale->new( language => 'zz' );
}
is( $xx->language, 'gb', 'Constructor: unknown locale falls back to gb' );

# ============================================================
# 3. Turkish casing — uc()
# ============================================================
is( $tr->uc('istanbul'), 'İSTANBUL', 'tr->uc: i → İ' );
is( $tr->uc('ankara'),   'ANKARA',   'tr->uc: plain ASCII' );

# ============================================================
# 4. Turkish casing — lc()
# ============================================================
# In Turkish: uppercase I → lowercase ı (dotless), İ → i
is( $tr->lc('I'),  'ı', 'tr->lc: I → ı' );
is( $tr->lc('İ'),  'i', 'tr->lc: İ → i' );
# Full word: ISTANBUL → ıstanbul (all I become ı in Turkish)
is( $tr->lc('ISTANBUL'), 'ıstanbul', 'tr->lc: ISTANBUL → ıstanbul (Turkish I→ı rule)' );

# ============================================================
# 5. English casing — no Turkish rules
# ============================================================
is( $en->uc('istanbul'), 'ISTANBUL', 'en->uc: plain uc no dotted-I' );
is( $en->lc('I'),        'i',        'en->lc: plain I → i' );

# ============================================================
# 6. ucfirst
# ============================================================
my $str = $tr->ucfirst('istanbul şehri büyük');
# After lc: 'istanbul şehri büyük'
# After ucfirst each word: 'İstanbul Şehri Büyük'
is( substr($str,0,1), 'İ', 'tr->ucfirst: first char İ' );

# ============================================================
# 7. sort (Unicode::Collate::Locale)
# ============================================================
my @words = qw(çay bal arı şeker güzel);
my @sorted_tr = $tr->sort( \@words );
# Turkish order: arı, bal, çay, güzel, şeker
is( $sorted_tr[0], 'arı',    'tr->sort: arı first' );
is( $sorted_tr[1], 'bal',    'tr->sort: bal second' );
is( $sorted_tr[2], 'çay',    'tr->sort: çay after bal' );
is( $sorted_tr[3], 'güzel',  'tr->sort: güzel' );
is( $sorted_tr[4], 'şeker',  'tr->sort: şeker last' );

# sort with array of arrays (AoA)
my @rows = ( [1,'çay'], [2,'bal'], [3,'arı'], [4,'şeker'] );
my @sorted_rows = $tr->sort( \@rows, 1 );
is( $sorted_rows[0][1], 'arı',   'tr->sort AoA: arı first' );
is( $sorted_rows[3][1], 'şeker', 'tr->sort AoA: şeker last' );

# ============================================================
# 8. to_ascii (NFD decomposition)
# ============================================================
is( $tr->to_ascii('çığlık'),   'ciglik', 'tr->to_ascii: çığlık → ciglik' );
is( $tr->to_ascii('şehir'),    'sehir',  'tr->to_ascii: şehir → sehir' );
is( $tr->to_ascii('Ğüzel'),    'Guzel',  'tr->to_ascii: Ğüzel → Guzel' );

# Slug mode (nonspace=1)
is( $tr->to_ascii('Çay Bardağı', 1), 'cay_bardagi', 'tr->to_ascii slug' );

# ============================================================
# 9. normalize
# ============================================================
my $norm = $tr->normalize('<b>Çay</b> & şeker');
# HTML stripped, & entity cleaned, Turkish chars kept
is( $norm, 'Çay & şeker', 'tr->normalize: strip HTML keep Turkish' );

# ============================================================
# 10. decode_entities
# ============================================================
is( $tr->decode_entities('&amp;lt;'), '&lt;', 'decode_entities: &amp; → &' );
is( $tr->decode_entities('&#199;'),   'Ç',    'decode_entities: &#199; → Ç' );
is( $tr->decode_entities('&ccedil;'), 'ç',    'decode_entities: &ccedil; → ç (tr locale)' );

# English locale has no &ccedil; extra — should pass through unchanged
is( $en->decode_entities('&amp;'), '&', 'en->decode_entities: &amp; → &' );

# ============================================================
# 11. num2text — Turkish
# ============================================================
is( $tr->num2text(0),     'Sıfır',       'num2text: 0 → Sıfır' );
is( $tr->num2text(1),     'Bir TL',      'num2text: 1 → Bir TL' );
is( $tr->num2text(10),    'On TL',       'num2text: 10 → On TL' );
is( $tr->num2text(100),   'Yüz TL',      'num2text: 100 → Yüz TL' );
is( $tr->num2text(1000),  'Bin TL',      'num2text: 1000 → Bin (not Bir Bin)' );
is( $tr->num2text(2000),  'İki Bin TL',  'num2text: 2000 → İki Bin TL' );
is( $tr->num2text(1000000), 'Bir Milyon TL', 'num2text: 1000000' );

# num2text — external numbers hash override
my %custom = (
    zero    => 'Zero',
    ones    => [qw(One Two Three Four Five Six Seven Eight Nine)],
    tens    => [qw(Ten Twenty Thirty Forty Fifty Sixty Seventy Eighty Ninety)],
    hundred => 'Hundred',
    thousand => 'Thousand',
    million  => 'Million',
    billion  => 'Billion',
    currency => { main => 'USD', sub => 'cent' },
    decimal_sep => '.',
    thousand_one_prefix => 1,
);
is( $tr->num2text(0,   numbers => \%custom), 'Zero',              'num2text: external 0' );
is( $tr->num2text(1,   numbers => \%custom), 'One USD',           'num2text: external 1' );
is( $tr->num2text(100, numbers => \%custom), 'One Hundred USD',   'num2text: external 100' );
is( $tr->num2text(1000,numbers => \%custom), 'One Thousand USD',  'num2text: external 1000' );

# Currency override
is( $tr->num2text(1, currency => { main => 'EUR', sub => 'cent' }),
    'Bir EUR', 'num2text: currency override' );

# ============================================================
# 12. first_char
# ============================================================
is( $tr->first_char('çay'),   'Ç', 'first_char: çay → Ç' );
is( $tr->first_char('arı'),   'A', 'first_char: arı → A' );
is( $tr->first_char('123'),   '0-9', 'first_char: number → 0-9' );

# ============================================================
# 13. substring (locale-independent)
# ============================================================
my $utf8_str = Encode::encode('UTF-8', 'Çaylık bahçe');
my $sub = $tr->substring($utf8_str, 6);
is( Encode::decode('UTF-8',$sub), 'Çaylık', 'substring: 6 chars UTF-8' );

# ============================================================
# 14. German locale (de)
# ============================================================
my $de = AmberDB::Locale->new( language => 'de' );
is( $de->language, 'de', 'de locale: loaded' );
is( $de->to_ascii('München'), 'Muenchen', 'de->to_ascii: ü → ue' );
is( $de->to_ascii('Straße'),  'Strasse',  'de->to_ascii: ß → ss' );

# ============================================================
# 15. French locale (fr)
# ============================================================
my $fr = AmberDB::Locale->new( language => 'fr' );
is( $fr->language, 'fr', 'fr locale: loaded' );
is( $fr->to_ascii('Château'), 'Chateau', 'fr->to_ascii: Château → Chateau' );
is( $fr->num2text(100),       'Cent EUR', 'fr->num2text: 100 → Cent EUR' );

# ============================================================
# 16. Spanish locale (es)
# ============================================================
my $es = AmberDB::Locale->new( language => 'es' );
is( $es->language, 'es', 'es locale: loaded' );
is( $es->to_ascii('Niño'),  'Nino',     'es->to_ascii: Niño → Nino' );
is( $es->num2text(1),       'Uno EUR',  'es->num2text: 1 → Uno EUR' );

# ============================================================
# 17. Russian locale (ru)
# ============================================================
my $ru = AmberDB::Locale->new( language => 'ru' );
is( $ru->language, 'ru', 'ru locale: loaded' );
is( $ru->num2text(100),     'Сто RUB',  'ru->num2text: 100 → Сто RUB' );

# ============================================================
# 18. Arabic locale (ar)
# ============================================================
my $ar = AmberDB::Locale->new( language => 'ar' );
is( $ar->language, 'ar', 'ar locale: loaded' );
is( $ar->num2text(1),      'واحد SAR', 'ar->num2text: 1 → واحد SAR' );

# ============================================================
# 19. Azerbaijani locale (az)
# ============================================================
my $az = AmberDB::Locale->new( language => 'az' );
is( $az->language, 'az', 'az locale: loaded' );
is( $az->lc('Ə'),           'ə',        'az->lc: Ə → ə' );
is( $az->to_ascii('Bakı'),  'Baki',     'az->to_ascii: Bakı → Baki' );

done_testing();

