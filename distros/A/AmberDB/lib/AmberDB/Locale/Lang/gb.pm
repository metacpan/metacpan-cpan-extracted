package AmberDB::Locale::Lang::gb;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-09-03';

# -------------------------------------------------------
# Global Base (gb) Locale Data for AmberDB::Locale.
#
# Pure data module — no logic, no methods other than data().
#
# Design Principles for Global Base (gb):
# 1. Universal Multilingual Support: Designed for international,
#    cross-border datasets combining English, Turkish, German,
#    French, Spanish, Italian, Scandinavian, and Slavic-Latin text.
# 2. Comprehensive Alphabet: alphabet_chars includes all European,
#    Nordic, and Turkish extended Latin letters so no valid characters
#    are stripped during text sanitization.
# 3. Permissive Search Regex: regex_map expands characters across their
#    accented and unaccented forms (e.g. searching 'cafe' matches 'café',
#    'munchen' matches 'münchen', 'seker' matches 'şeker').
# 4. Canonical Accent Folding: accent_map flattens accented letters
#    to base Latin forms for high-recall inverted search indexing (.src).
# 5. Lossless ASCII Transliteration: ascii_map cleanly converts
#    non-decomposable Unicode ligatures (ß->ss, æ->ae, œ->oe, ø->o,
#    ı->i, ł->l, ð->d, þ->th, ə->e) for URL slugs and ASCII IDs.
# 6. International Formatting: Default numbers, dates, and currency
#    follow ISO and international English conventions (USD/cent, . decimal).
# -------------------------------------------------------
sub data {
    return {

        # ---------------------------------------------------------
        # Casing special-cases
        # uc_map: applied BEFORE Perl's uc()
        # lc_map: applied BEFORE Perl's lc()
        # Standard Unicode casing handles almost all Latin chars.
        # Turkish dotted capital İ -> i is preserved during lc.
        # ---------------------------------------------------------
        uc_map => {},
        lc_map => {
            "\x{130}" => 'i',    # Turkish dotted capital İ -> i
        },

        # ---------------------------------------------------------
        # Case-insensitive & accent-tolerant search regex character map
        # Maps both base and accented characters to a regex character class
        # covering all regional variations.
        # ---------------------------------------------------------
        regex_map => {
            # A variations: a, á, à, â, ä, ã, å, ā, æ
            'a'       => '[aA\x{E1}\x{C1}\x{E0}\x{C0}\x{E2}\x{C2}\x{E4}\x{C4}\x{E3}\x{C3}\x{E5}\x{C5}\x{101}\x{100}\x{E6}\x{C6}]',
            'A'       => '[aA\x{E1}\x{C1}\x{E0}\x{C0}\x{E2}\x{C2}\x{E4}\x{C4}\x{E3}\x{C3}\x{E5}\x{C5}\x{101}\x{100}\x{E6}\x{C6}]',

            # C variations: c, ç, ć, č
            'c'       => '[cC\x{E7}\x{C7}\x{107}\x{106}\x{10D}\x{10C}]',
            'C'       => '[cC\x{E7}\x{C7}\x{107}\x{106}\x{10D}\x{10C}]',
            "\x{E7}"  => '[cC\x{E7}\x{C7}\x{107}\x{106}\x{10D}\x{10C}]', # ç
            "\x{C7}"  => '[cC\x{E7}\x{C7}\x{107}\x{106}\x{10D}\x{10C}]', # Ç

            # D variations: d, ð, đ
            'd'       => '[dD\x{F0}\x{D0}\x{111}\x{110}]',
            'D'       => '[dD\x{F0}\x{D0}\x{111}\x{110}]',

            # E variations: e, é, è, ê, ë, ē, ė, ę, ə
            'e'       => '[eE\x{E9}\x{C9}\x{E8}\x{C8}\x{EA}\x{CA}\x{EB}\x{CB}\x{113}\x{112}\x{117}\x{116}\x{119}\x{118}\x{259}\x{18F}]',
            'E'       => '[eE\x{E9}\x{C9}\x{E8}\x{C8}\x{EA}\x{CA}\x{EB}\x{CB}\x{113}\x{112}\x{117}\x{116}\x{119}\x{118}\x{259}\x{18F}]',

            # G variations: g, ğ
            'g'       => '[gG\x{11F}\x{11E}]',
            'G'       => '[gG\x{11F}\x{11E}]',
            "\x{11F}" => '[gG\x{11F}\x{11E}]', # ğ
            "\x{11E}" => '[gG\x{11F}\x{11E}]', # Ğ

            # I variations: i, I, ı, İ, î, ï, í, ì, ī
            'i'       => '[iI\x{131}I\x{130}i\x{EE}\x{CE}\x{EF}\x{CF}\x{ED}\x{CD}\x{EC}\x{CC}\x{12B}\x{12A}]',
            'I'       => '[iI\x{131}I\x{130}i\x{EE}\x{CE}\x{EF}\x{CF}\x{ED}\x{CD}\x{EC}\x{CC}\x{12B}\x{12A}]',
            "\x{131}" => '[iI\x{131}I\x{130}i\x{EE}\x{CE}\x{EF}\x{CF}\x{ED}\x{CD}\x{EC}\x{CC}\x{12B}\x{12A}]', # ı
            "\x{130}" => '[iI\x{131}I\x{130}i\x{EE}\x{CE}\x{EF}\x{CF}\x{ED}\x{CD}\x{EC}\x{CC}\x{12B}\x{12A}]', # İ

            # L variations: l, ł
            'l'       => '[lL\x{142}\x{141}]',
            'L'       => '[lL\x{142}\x{141}]',

            # N variations: n, ñ, ń
            'n'       => '[nN\x{F1}\x{D1}\x{144}\x{143}]',
            'N'       => '[nN\x{F1}\x{D1}\x{144}\x{143}]',

            # O variations: o, ó, ò, ô, ö, õ, ø, ō, œ
            'o'       => '[oO\x{F3}\x{D3}\x{F2}\x{D2}\x{F4}\x{D4}\x{F6}\x{D6}\x{F5}\x{D5}\x{F8}\x{D8}\x{14D}\x{14C}\x{153}\x{152}]',
            'O'       => '[oO\x{F3}\x{D3}\x{F2}\x{D2}\x{F4}\x{D4}\x{F6}\x{D6}\x{F5}\x{D5}\x{F8}\x{D8}\x{14D}\x{14C}\x{153}\x{152}]',
            "\x{F6}"  => '[oO\x{F3}\x{D3}\x{F2}\x{D2}\x{F4}\x{D4}\x{F6}\x{D6}\x{F5}\x{D5}\x{F8}\x{D8}\x{14D}\x{14C}\x{153}\x{152}]', # ö
            "\x{D6}"  => '[oO\x{F3}\x{D3}\x{F2}\x{D2}\x{F4}\x{D4}\x{F6}\x{D6}\x{F5}\x{D5}\x{F8}\x{D8}\x{14D}\x{14C}\x{153}\x{152}]', # Ö

            # S variations: s, ş, ś, š, ß
            's'       => '[sS\x{15F}\x{15E}\x{15B}\x{15A}\x{161}\x{160}\x{DF}]',
            'S'       => '[sS\x{15F}\x{15E}\x{15B}\x{15A}\x{161}\x{160}\x{DF}]',
            "\x{15F}" => '[sS\x{15F}\x{15E}\x{15B}\x{15A}\x{161}\x{160}\x{DF}]', # ş
            "\x{15E}" => '[sS\x{15F}\x{15E}\x{15B}\x{15A}\x{161}\x{160}\x{DF}]', # Ş
            "\x{DF}"  => '[sS\x{15F}\x{15E}\x{15B}\x{15A}\x{161}\x{160}\x{DF}]', # ß

            # T variations: t, þ
            't'       => '[tT\x{FE}\x{DE}]',
            'T'       => '[tT\x{FE}\x{DE}]',

            # U variations: u, ú, ù, û, ü, ū
            'u'       => '[uU\x{FA}\x{DA}\x{F9}\x{D9}\x{FB}\x{DB}\x{FC}\x{DC}\x{16B}\x{16A}]',
            'U'       => '[uU\x{FA}\x{DA}\x{F9}\x{D9}\x{FB}\x{DB}\x{FC}\x{DC}\x{16B}\x{16A}]',
            "\x{FC}"  => '[uU\x{FA}\x{DA}\x{F9}\x{D9}\x{FB}\x{DB}\x{FC}\x{DC}\x{16B}\x{16A}]', # ü
            "\x{DC}"  => '[uU\x{FA}\x{DA}\x{F9}\x{D9}\x{FB}\x{DB}\x{FC}\x{DC}\x{16B}\x{16A}]', # Ü

            # Y variations: y, ý, ÿ
            'y'       => '[yY\x{FD}\x{DD}\x{FF}]',
            'Y'       => '[yY\x{FD}\x{DD}\x{FF}]',

            # Z variations: z, ź, ż, ž
            'z'       => '[zZ\x{17A}\x{179}\x{17C}\x{17B}\x{17E}\x{17D}]',
            'Z'       => '[zZ\x{17A}\x{179}\x{17C}\x{17B}\x{17E}\x{17D}]',
        },

        # ---------------------------------------------------------
        # Phonetic assimilation & double-consonant reduction
        # ---------------------------------------------------------
        phonetic_map => [
            [ 'bb' => 'b' ],
            [ 'dd' => 'd' ],
            [ 'ff' => 'f' ],
            [ 'gg' => 'g' ],
            [ 'll' => 'l' ],
            [ 'mm' => 'm' ],
            [ 'nn' => 'n' ],
            [ 'pp' => 'p' ],
            [ 'rr' => 'r' ],
            [ 'ss' => 's' ],
            [ 'tt' => 't' ],
            [ 'zz' => 'z' ],
        ],

        # ---------------------------------------------------------
        # Optional custom sort collation overrides.
        # Unicode::Collate handles standard UCA collation.
        # ---------------------------------------------------------
        sort_map => {},

        # ---------------------------------------------------------
        # Alphabet character class for normalize() & safe string handling.
        # Characters considered valid letters alongside standard a-zA-Z.
        # Encompasses Latin-1 Supplement, Latin Extended-A, and Nordic/Turkish letters.
        # ---------------------------------------------------------
        alphabet_chars =>
            "\x{C0}\x{C1}\x{C2}\x{C3}\x{C4}\x{C5}\x{C6}\x{C7}\x{C8}\x{C9}\x{CA}\x{CB}" .
            "\x{CC}\x{CD}\x{CE}\x{CF}\x{D0}\x{D1}\x{D2}\x{D3}\x{D4}\x{D5}\x{D6}\x{D8}" .
            "\x{D9}\x{DA}\x{DB}\x{DC}\x{DD}\x{DE}\x{DF}" .
            "\x{E0}\x{E1}\x{E2}\x{E3}\x{E4}\x{E5}\x{E6}\x{E7}\x{E8}\x{E9}\x{EA}\x{EB}" .
            "\x{EC}\x{ED}\x{EE}\x{EF}\x{F0}\x{F1}\x{F2}\x{F3}\x{F4}\x{F5}\x{F6}\x{F8}" .
            "\x{F9}\x{FA}\x{FB}\x{FC}\x{FD}\x{FE}\x{FF}" .
            "\x{11E}\x{11F}\x{130}\x{131}\x{15E}\x{15F}" .  # Ğ ğ İ ı Ş ş (Turkish/Azeri)
            "\x{106}\x{107}\x{10C}\x{10D}\x{110}\x{111}" .  # Ć ć Č č Đ đ (Slavic Latin)
            "\x{141}\x{142}\x{143}\x{144}\x{15A}\x{15B}" .  # Ł ł Ń ń Ś ś
            "\x{160}\x{161}\x{179}\x{17A}\x{17B}\x{17C}\x{17D}\x{17E}" . # Š š Ź ź Ż ż Ž ž
            "\x{152}\x{153}\x{18F}\x{259}",                  # Œ œ Ə ə (French / Azeri)

        # ---------------------------------------------------------
        # Accent normalization map — used by normalize().
        # Maps accented/regional characters to their clean base Latin forms.
        # ---------------------------------------------------------
        accent_map => {
            # A / a
            "\x{E0}" => 'a',  "\x{E1}" => 'a',  "\x{E2}" => 'a',  "\x{E3}" => 'a',  "\x{E4}" => 'a',  "\x{E5}" => 'a',  "\x{E6}" => 'ae',
            "\x{C0}" => 'A',  "\x{C1}" => 'A',  "\x{C2}" => 'A',  "\x{C3}" => 'A',  "\x{C4}" => 'A',  "\x{C5}" => 'A',  "\x{C6}" => 'AE',

            # C / c
            "\x{E7}" => 'c',  "\x{C7}" => 'C',  # ç, Ç
            "\x{107}" => 'c', "\x{106}" => 'C', # ć, Ć
            "\x{10D}" => 'c', "\x{10C}" => 'C', # č, Č

            # D / d
            "\x{F0}" => 'd',  "\x{D0}" => 'D',  # ð, Ð
            "\x{111}" => 'd', "\x{110}" => 'D', # đ, Đ

            # E / e
            "\x{E8}" => 'e',  "\x{E9}" => 'e',  "\x{EA}" => 'e',  "\x{EB}" => 'e',
            "\x{C8}" => 'E',  "\x{C9}" => 'E',  "\x{CA}" => 'E',  "\x{CB}" => 'E',
            "\x{259}" => 'e', "\x{18F}" => 'E', # ə, Ə

            # G / g
            "\x{11F}" => 'g', "\x{11E}" => 'G', # ğ, Ğ

            # I / i
            "\x{EC}" => 'i',  "\x{ED}" => 'i',  "\x{EE}" => 'i',  "\x{EF}" => 'i',
            "\x{CC}" => 'I',  "\x{CD}" => 'I',  "\x{CE}" => 'I',  "\x{CF}" => 'I',
            "\x{131}" => 'i', "\x{130}" => 'I', # ı, İ

            # L / l
            "\x{142}" => 'l', "\x{141}" => 'L', # ł, Ł

            # N / n
            "\x{F1}" => 'n',  "\x{D1}" => 'N',  # ñ, Ñ
            "\x{144}" => 'n', "\x{143}" => 'N', # ń, Ń

            # O / o
            "\x{F2}" => 'o',  "\x{F3}" => 'o',  "\x{F4}" => 'o',  "\x{F5}" => 'o',  "\x{F6}" => 'o',  "\x{F8}" => 'o',
            "\x{D2}" => 'O',  "\x{D3}" => 'O',  "\x{D4}" => 'O',  "\x{D5}" => 'O',  "\x{D6}" => 'O',  "\x{D8}" => 'O',
            "\x{153}" => 'oe', "\x{152}" => 'OE', # œ, Œ

            # S / s
            "\x{15F}" => 's', "\x{15E}" => 'S', # ş, Ş
            "\x{15B}" => 's', "\x{15A}" => 'S', # ś, Ś
            "\x{161}" => 's', "\x{160}" => 'S', # š, Š
            "\x{DF}"  => 'ss',                  # ß

            # T / t
            "\x{FE}" => 'th', "\x{DE}" => 'TH', # þ, Þ

            # U / u
            "\x{F9}" => 'u',  "\x{FA}" => 'u',  "\x{FB}" => 'u',  "\x{FC}" => 'u',
            "\x{D9}" => 'U',  "\x{DA}" => 'U',  "\x{DB}" => 'U',  "\x{DC}" => 'U',

            # Y / y
            "\x{FD}" => 'y',  "\x{DD}" => 'Y',  "\x{FF}" => 'y',

            # Z / z
            "\x{17A}" => 'z', "\x{179}" => 'Z', # ź, Ź
            "\x{17C}" => 'z', "\x{17B}" => 'Z', # ż, Ż
            "\x{17E}" => 'z', "\x{17D}" => 'Z', # ž, Ž
        },

        # ---------------------------------------------------------
        # ASCII transliteration pre-map — used BEFORE NFD in to_ascii().
        # Converts non-decomposable ligatures and special glyphs.
        # ---------------------------------------------------------
        ascii_map => {
            "\x{DF}"  => 'ss',                    # ß → ss
            "\x{E6}"  => 'ae',  "\x{C6}"  => 'AE',# æ → ae, Æ → AE
            "\x{153}" => 'oe',  "\x{152}" => 'OE',# œ → oe, Œ → OE
            "\x{131}" => 'i',                     # ı → i
            "\x{F0}"  => 'd',   "\x{D0}"  => 'D', # ð → d, Ð → D
            "\x{FE}"  => 'th',  "\x{DE}"  => 'TH',# þ → th, Þ → TH
            "\x{F8}"  => 'o',   "\x{D8}"  => 'O', # ø → o, Ø → O
            "\x{142}" => 'l',   "\x{141}" => 'L', # ł → l, Ł → L
            "\x{111}" => 'd',   "\x{110}" => 'D', # đ → d, Đ → D
            "\x{259}" => 'e',   "\x{18F}" => 'E', # ə → e, Ə → E
        },

        # ---------------------------------------------------------
        # num2text number words (International English standard)
        # ---------------------------------------------------------
        numbers => {
            zero     => 'Zero',
            negative => 'Minus',
            ones     => [qw(One Two Three Four Five Six Seven Eight Nine)],
            tens     => [qw(Ten Twenty Thirty Forty Fifty Sixty Seventy Eighty Ninety)],
            hundred  => 'Hundred',
            thousand => 'Thousand',
            million  => 'Million',
            billion  => 'Billion',
            currency => { main => 'USD', sub => 'cent' },
            decimal_sep => '.',
            hundred_one_prefix  => 1,  # One Hundred
            thousand_one_prefix => 1,  # One Thousand
        },

        # ---------------------------------------------------------
        # HTML entity extras
        # ---------------------------------------------------------
        html_entities => {},

        # ---------------------------------------------------------
        # Month and Day names (International English)
        # ---------------------------------------------------------
        months => [
            "January", "February", "March",     "April",   "May",      "June",
            "July",    "August",   "September", "October", "November", "December"
        ],
        days => [
            "Sunday",   "Monday", "Tuesday", "Wednesday",
            "Thursday", "Friday", "Saturday"
        ],

        # ---------------------------------------------------------
        # Formatting metadata (number, currency, date)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => '.',
            group_sep   => ',',
            group_size  => 3,
        },
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::gb - Global Base Language Definition and Default Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('gb');

=head1 DESCRIPTION

Provides Global Base (gb) universal casing, multilingual extended Latin character maps, search regex patterns, canonical accent folding, ASCII transliteration, and international formatting for the AmberDB locale engine. Global Base (gb) serves as the default and fallback locale.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
