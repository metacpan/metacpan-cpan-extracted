package AmberDB::Locale::Lang::ar;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-23';

# -------------------------------------------------------
# Arabic locale data for AmberDB::Locale.
# Pure data module — no logic.
# -------------------------------------------------------
sub data {
    return {
        uc_map => {},
        lc_map => {},
        regex_map => {},
        phonetic_map => [
            [ "[\x{0622}\x{0623}\x{0625}]" => "\x{0627}" ], # أ, إ, آ → ا (Alef variants)
            [ "\x{0629}\$"                 => "\x{0647}" ], # ة → ه (Ta Marbuta)
            [ "\x{0649}\$"                 => "\x{064A}" ], # ى → ي (Alif Maqsurah)
        ],
        sort_map => {},

        # Arabic characters range (U+0600 to U+06FF) + Eastern Arabic numerals
        alphabet_chars => "\x{0600}-\x{06FF}",

        accent_map => {},

        # Arabic to Latin ASCII transliteration (SATTS / Buckwalter style)
        ascii_map => {
            "\x{0621}" => 'a',  # أ
            "\x{0627}" => 'a',  # ا
            "\x{0628}" => 'b',  # ب
            "\x{062A}" => 't',  # ت
            "\x{062B}" => 'th', # ث
            "\x{062C}" => 'j',  # ج
            "\x{062D}" => 'h',  # ح
            "\x{062E}" => 'kh', # خ
            "\x{062F}" => 'd',  # د
            "\x{0630}" => 'dh', # ذ
            "\x{0631}" => 'r',  # ر
            "\x{0632}" => 'z',  # ز
            "\x{0633}" => 's',  # س
            "\x{0634}" => 'sh', # ش
            "\x{0635}" => 's',  # ص
            "\x{0636}" => 'd',  # ض
            "\x{0637}" => 't',  # ط
            "\x{0638}" => 'z',  # ظ
            "\x{0639}" => 'a',  # ع
            "\x{063A}" => 'gh', # غ
            "\x{0641}" => 'f',  # ف
            "\x{0642}" => 'q',  # ق
            "\x{0643}" => 'k',  # ك
            "\x{0644}" => 'l',  # ل
            "\x{0645}" => 'm',  # م
            "\x{0646}" => 'n',  # ن
            "\x{0647}" => 'h',  # ه
            "\x{0648}" => 'w',  # و
            "\x{064A}" => 'y',  # ي
        },

        # Arabic numbers (num2text)
        numbers => {
            zero     => 'صفر',
            ones     => [qw(واحد اثنان ثلاثة أربعة خمسة ستة سبعة ثمانية تسعة)],
            tens     => [qw(عشرة عشرون ثلاثون أربعون خمسون ستون سبعون ثمانون تسعون)],
            hundred  => 'مائة',
            thousand => 'ألف',
            million  => 'مليون',
            billion  => 'مليار',
            currency => { main => 'SAR', sub => 'هللة' },
            decimal_sep => '٫',
            hundred_one_prefix  => 0,  # "مائة" not "واحد مائة"
            thousand_one_prefix => 0,  # "ألف" not "واحد ألف"
        },

        html_entities => {},

        # Month and Day names (Arabic)
        # ---------------------------------------------------------
        months => [
            "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
            "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
        ],
        days => [
            "الأحد", "الإثنين", "الثلاثاء", "الأربعاء",
            "الخميس", "الجمعة", "السبت"
        ],

        # ---------------------------------------------------------
        # Formatting metadata (number, currency, date, plural)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => '٫',
            group_sep   => '٬',
            group_size  => 3,
        },

        default_currency  => 'SAR',
        currency_position => 'suffix',
        currency_space    => 1,

        date_format => {
            short    => 'DD/MM/YYYY',
            medium   => 'D MMM YYYY',
            long     => 'D MMMM YYYY',
            full     => 'dddd، D MMMM YYYY',
            time     => 'HH:mm',
            datetime => 'DD/MM/YYYY HH:mm',
        },

        plural_rule => 'zero{n==0}one{n==1}two{n==2}few{n%100>=3&&n%100<=10}many{n%100>=11&&n%100<=99}other',
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::ar - Arabic Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('ar');

=head1 DESCRIPTION

Provides Arabic (ar) casing, character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
