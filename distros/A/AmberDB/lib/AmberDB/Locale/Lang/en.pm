package AmberDB::Locale::Lang::en;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-22';

# -------------------------------------------------------
# Pure data module — no logic, no methods other than data().
# Returns a hash-ref consumed by AmberDB::Locale.
#
# Global Base (gb) is the default/fallback locale.
# Perl's built-in uc/lc already handle ASCII correctly,
# so most maps here are empty (no special casing needed).
# -------------------------------------------------------
sub data {
    return {

        # ---------------------------------------------------------
        # Casing special-cases that Perl's uc/lc does NOT handle
        # correctly for this language.
        #
        # uc_map : applied BEFORE Perl's uc()
        #   key   => character to replace BEFORE uc()
        #   value => what to replace it with
        #
        # lc_map : applied BEFORE Perl's lc()
        #   key   => character to replace BEFORE lc()
        #   value => what to replace it with
        # ---------------------------------------------------------
        uc_map => {},    # English: no pre-uc substitutions needed
        lc_map => {},    # English: no pre-lc substitutions needed
        regex_map => {},
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
        # Unicode::Collate::Locale handles standard collation automatically.
        # ---------------------------------------------------------
        sort_map => {},


        # ---------------------------------------------------------
        # Alphabet character class for normalize().
        # Used inside a character class: [a-zA-Z$alphabet_chars]
        # Leave empty for English — only a-zA-Z is kept.
        # ---------------------------------------------------------
        alphabet_chars => '',

        # ---------------------------------------------------------
        # Accent normalization map — used by normalize().
        # Maps accented/exotic chars to their locale equivalent.
        # For English: map accented chars back to plain ASCII base.
        # ---------------------------------------------------------
        accent_map => {
            "\x{E0}" => 'a', "\x{E1}" => 'a', "\x{E2}" => 'a', "\x{E4}" => 'a', "\x{E6}" => 'ae',
            "\x{E8}" => 'e', "\x{E9}" => 'e', "\x{EA}" => 'e', "\x{EB}" => 'e',
            "\x{EC}" => 'i', "\x{ED}" => 'i', "\x{EE}" => 'i', "\x{EF}" => 'i',
            "\x{F2}" => 'o', "\x{F3}" => 'o', "\x{F4}" => 'o', "\x{F6}" => 'o',
            "\x{F9}" => 'u', "\x{FA}" => 'u', "\x{FB}" => 'u', "\x{FC}" => 'u',
            "\x{F1}" => 'n', "\x{E7}" => 'c', "\x{DF}" => 'ss',
            "\x{C0}" => 'A', "\x{C1}" => 'A', "\x{C2}" => 'A', "\x{C4}" => 'A', "\x{C6}" => 'AE',
            "\x{C8}" => 'E', "\x{C9}" => 'E', "\x{CA}" => 'E', "\x{CB}" => 'E',
            "\x{CC}" => 'I', "\x{CD}" => 'I', "\x{CE}" => 'I', "\x{CF}" => 'I',
            "\x{D2}" => 'O', "\x{D3}" => 'O', "\x{D4}" => 'O', "\x{D6}" => 'O',
            "\x{D9}" => 'U', "\x{DA}" => 'U', "\x{DB}" => 'U', "\x{DC}" => 'U',
            "\x{D1}" => 'N', "\x{C7}" => 'C',
        },

        # ---------------------------------------------------------
        # ASCII transliteration pre-map — used BEFORE NFD in to_ascii().
        #
        # For English, NFD + \p{M} strip handles ALL accented chars
        # automatically (à→a, é→e, ü→u, ç→c, etc.).
        #
        # Only exceptions that NFD cannot decompose:
        #   ß (U+00DF) — no NFD decomposition → ss
        #   æ (U+00E6) — no NFD decomposition → ae  (ligature)
        #   Æ (U+00C6) — no NFD decomposition → AE
        #   œ (U+0153) — no NFD decomposition → oe  (ligature)
        #   Œ (U+0152) — no NFD decomposition → OE
        # ---------------------------------------------------------
        ascii_map => {
            "\x{DF}"  => 'ss',   # ß → ss
            "\x{E6}"  => 'ae',  "\x{C6}"  => 'AE',   # æ → ae, Æ → AE
            "\x{153}" => 'oe',  "\x{152}" => 'OE',   # œ → oe, Œ → OE
        },


        # ---------------------------------------------------------
        # num2text number words
        # ---------------------------------------------------------
        numbers => {
            zero     => 'Zero',
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
        # Locale-specific HTML entity extras.
        # Universal entities (&amp; &lt; &gt; etc.) are handled
        # inside Language.pm and do NOT need to be listed here.
        # Only add language-specific named entities.
        # ---------------------------------------------------------
        html_entities => {},    # English has no extra named entities

        # ---------------------------------------------------------
        # Month and Day names
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
        # Formatting metadata (number, currency, date, plural)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => '.',
            group_sep   => ',',
            group_size  => 3,
        },

        default_currency  => 'USD',
        currency_position => 'prefix',
        currency_space    => 0,

        date_format => {
            short    => 'MM/DD/YYYY',
            medium   => 'MMM D, YYYY',
            long     => 'MMMM D, YYYY',
            full     => 'dddd, MMMM D, YYYY',
            time     => 'HH:mm',
            datetime => 'MM/DD/YYYY HH:mm',
        },

        plural_rule => 'one{n==1}other',
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::en - English Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('en');

=head1 DESCRIPTION

Provides English (en) casing, character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
