package AmberDB::Locale::Lang::ja;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-08-12';

# -------------------------------------------------------
# Japanese (日本語) locale data for AmberDB::Locale.
# Pure data module — no logic.
# Supports Hiragana, Katakana, Kanji, Romaji transliteration,
# JPY currency formatting, Japanese date formats, and Japanese num2text.
# -------------------------------------------------------
sub data {
    return {
        uc_map => {},
        lc_map => {},
        regex_map => {},

        # Hiragana <-> Katakana phonetic equivalence rules for search
        phonetic_map => [
            [ "\x{30FC}" => '' ], # Long vowel mark (ー) normalization
        ],

        sort_map => {},

        # Unicode character ranges for Japanese:
        #   \x{3040}-\x{309F} : Hiragana (ひらがな)
        #   \x{30A0}-\x{30FF} : Katakana (カタカナ)
        #   \x{4E00}-\x{9FAF} : Kanji (漢字 CJK Ideographs)
        #   \x{FF00}-\x{FFEF} : Halfwidth and Fullwidth Forms (全角・半角)
        alphabet_chars => "\x{3040}-\x{309F}\x{30A0}-\x{30FF}\x{4E00}-\x{9FAF}\x{FF00}-\x{FFEF}",

        accent_map => {},

        # Romaji transliteration (Hepburn System) & Fullwidth numeral normalization
        ascii_map => {
            # Fullwidth Digits
            "\x{FF10}" => '0', "\x{FF11}" => '1', "\x{FF12}" => '2', "\x{FF13}" => '3', "\x{FF14}" => '4',
            "\x{FF15}" => '5', "\x{FF16}" => '6', "\x{FF17}" => '7', "\x{FF18}" => '8', "\x{FF19}" => '9',
            # Vowels (Hiragana & Katakana)
            "\x{3042}" => 'a',  "\x{30A2}" => 'a',   # あ, ア
            "\x{3044}" => 'i',  "\x{30A4}" => 'i',   # い, イ
            "\x{3046}" => 'u',  "\x{30A6}" => 'u',   # う, ウ
            "\x{3048}" => 'e',  "\x{30A8}" => 'e',   # え, エ
            "\x{304A}" => 'o',  "\x{30AA}" => 'o',   # お, オ
            # Ka-row
            "\x{304B}" => 'ka', "\x{30AB}" => 'ka',  # か, カ
            "\x{304D}" => 'ki', "\x{30AD}" => 'ki',  # き, キ
            "\x{304F}" => 'ku', "\x{30AF}" => 'ku',  # く, ク
            "\x{3051}" => 'ke', "\x{30B1}" => 'ke',  # け, ケ
            "\x{3053}" => 'ko', "\x{30B3}" => 'ko',  # こ, コ
            # Sa-row
            "\x{3055}" => 'sa', "\x{30B5}" => 'sa',  # さ, サ
            "\x{3057}" => 'shi',"\x{30B7}" => 'shi', # し, シ
            "\x{3059}" => 'su', "\x{30B9}" => 'su',  # す, ス
            "\x{305B}" => 'se', "\x{30BB}" => 'se',  # せ, セ
            "\x{305D}" => 'so', "\x{30BD}" => 'so',  # そ, ソ
            # Ta-row
            "\x{305F}" => 'ta', "\x{30BF}" => 'ta',  # た, タ
            "\x{3061}" => 'chi',"\x{30C1}" => 'chi', # ち, チ
            "\x{3064}" => 'tsu',"\x{30C4}" => 'tsu', # つ, ツ
            "\x{3066}" => 'te', "\x{30C6}" => 'te',  # て, テ
            "\x{3068}" => 'to', "\x{30C8}" => 'to',  # と, ト
            # Na-row
            "\x{306A}" => 'na', "\x{30CA}" => 'na',  # な, ナ
            "\x{306B}" => 'ni', "\x{30CB}" => 'ni',  # に, ニ
            "\x{306C}" => 'nu', "\x{30CC}" => 'nu',  # ぬ, ヌ
            "\x{306D}" => 'ne', "\x{30CD}" => 'ne',  # ね, ネ
            "\x{306E}" => 'no', "\x{30CE}" => 'no',  # の, ノ
            # Ha-row
            "\x{306F}" => 'ha', "\x{30CF}" => 'ha',  # は, ハ
            "\x{3072}" => 'hi', "\x{30D2}" => 'hi',  # ひ, ヒ
            "\x{3075}" => 'fu', "\x{30D5}" => 'fu',  # ふ, フ
            "\x{3078}" => 'he', "\x{30D8}" => 'he',  # へ, ヘ
            "\x{307B}" => 'ho', "\x{30DB}" => 'ho',  # ほ, ホ
            # Ma-row
            "\x{307E}" => 'ma', "\x{30DE}" => 'ma',  # ま, マ
            "\x{307F}" => 'mi', "\x{30DF}" => 'mi',  # み, ミ
            "\x{3080}" => 'mu', "\x{30E0}" => 'mu',  # む, ム
            "\x{3081}" => 'me', "\x{30E1}" => 'me',  # め, メ
            "\x{3082}" => 'mo', "\x{30E2}" => 'mo',  # も, モ
            # Ya-row
            "\x{3084}" => 'ya', "\x{30E4}" => 'ya',  # や, ヤ
            "\x{3086}" => 'yu', "\x{30E6}" => 'yu',  # ゆ, ユ
            "\x{3088}" => 'yo', "\x{30E8}" => 'yo',  # よ, ヨ
            # Ra-row
            "\x{3089}" => 'ra', "\x{30E9}" => 'ra',  # ら, ラ
            "\x{308A}" => 'ri', "\x{30EA}" => 'ri',  # り, リ
            "\x{308B}" => 'ru', "\x{30EB}" => 'ru',  # る, ル
            "\x{308C}" => 're', "\x{30EC}" => 're',  # れ, レ
            "\x{308D}" => 'ro', "\x{30ED}" => 'ro',  # ろ, ロ
            # Wa-row & N
            "\x{308F}" => 'wa', "\x{30EF}" => 'wa',  # わ, ワ
            "\x{3092}" => 'wo', "\x{30F2}" => 'wo',  # を, ヲ
            "\x{3093}" => 'n',  "\x{30F3}" => 'n',   # ん, ン
        },

        # Japanese numbers (num2text)
        numbers => {
            zero     => '零',
            ones     => [qw(一 二 三 四 五 六 七 八 九)],
            tens     => [qw(十 二十 三十 四十 五十 六十 七十 八十 九十)],
            hundred  => '百',
            thousand => '千',
            million  => '百万',
            billion  => '十億',
            currency => { main => '円', sub => '銭' },
            decimal_sep => '.',
            hundred_one_prefix  => 0,  # 百 (not 一百)
            thousand_one_prefix => 0,  # 千 (not 一千)
        },

        html_entities => {
            '&yen;' => "\x{00A5}",
        },

        # Month and Day names (Japanese)
        months => [
            "1月", "2月", "3月", "4月", "5月", "6月",
            "7月", "8月", "9月", "10月", "11月", "12月"
        ],
        days => [
            "日曜日", "月曜日", "火曜日", "水曜日",
            "木曜日", "金曜日", "土曜日"
        ],

        # Formatting metadata (number, currency, date, plural)
        number_format => {
            decimal_sep => '.',
            group_sep   => ',',
            group_size  => 3,
        },

        default_currency  => 'JPY',
        currency_position => 'prefix',
        currency_space    => 0,

        date_format => {
            short    => 'YYYY/MM/DD',
            medium   => 'YYYY年M月D日',
            long     => 'YYYY年MM月DD日',
            full     => 'YYYY年MM月DD日(dddd)',
            time     => 'HH:mm',
            datetime => 'YYYY/MM/DD HH:mm',
        },

        plural_rule => 'other', # Japanese has no grammatical plurals
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::ja - Japanese Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('ja');

=head1 DESCRIPTION

Provides Japanese (ja) character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
