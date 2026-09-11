package AmberDB::Locale::Lang::de;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-22';

# -------------------------------------------------------
# German locale data for AmberDB::Locale.
# Pure data module — no logic.
#
# German-specific sort order:
#   DIN 5007 Variant 1 (dictionary sorting): ä ≈ a, ö ≈ o, ü ≈ u (Unicode::Collate default)
#   DIN 5007 Variant 2 (phonebook sorting): ä = ae, ö = oe, ü = ue (used in to_ascii)
#   ß (Eszett) sorts like ss
# -------------------------------------------------------
sub data {
    return {

        # ---------------------------------------------------------
        # Casing special-cases
        # German: ß → SS on uppercase (Perl >=5.22 handles this),
        # but we add it explicitly for older Perl compatibility.
        # ---------------------------------------------------------
        uc_map => {
            "\x{DF}" => 'SS',   # ß → SS (Großes Eszett U+1E9E not widely used)
        },
        lc_map => {},    # German: no special pre-lc substitutions

        regex_map => {
            'ä'      => '[äÄ]',
            'Ä'      => '[äÄ]',
            'ö'      => '[öÖ]',
            'Ö'      => '[öÖ]',
            'ü'      => '[üÜ]',
            'Ü'      => '[üÜ]',
            "\x{DF}" => '(?:ß|SS|ss)',
        },

        # Auslautverhärtung (Final-devoicing) rules
        phonetic_map => [
            [ 'b$' => 'p' ],
            [ 'd$' => 't' ],
            [ 'g$' => 'k' ],
            [ 'v$' => 'f' ],
        ],

        # ---------------------------------------------------------
        # Optional custom sort collation overrides.
        # Unicode::Collate::Locale handles standard collation automatically.
        # ---------------------------------------------------------
        sort_map => {},


        # ---------------------------------------------------------
        # Alphabet character class for normalize()
        # ---------------------------------------------------------
        alphabet_chars => "\x{E4}\x{C4}\x{F6}\x{D6}\x{FC}\x{DC}\x{DF}",
        #                   ä      Ä      ö      Ö      ü      Ü      ß

        # ---------------------------------------------------------
        # Accent normalization — map accented chars to German equivalents
        # ---------------------------------------------------------
        accent_map => {
            "\x{E0}" => 'a', "\x{E1}" => 'a', "\x{E2}" => 'a',
            "\x{E8}" => 'e', "\x{E9}" => 'e', "\x{EA}" => 'e', "\x{EB}" => 'e',
            "\x{EC}" => 'i', "\x{ED}" => 'i', "\x{EE}" => 'i', "\x{EF}" => 'i',
            "\x{F2}" => 'o', "\x{F3}" => 'o', "\x{F4}" => 'o',
            "\x{F9}" => 'u', "\x{FA}" => 'u', "\x{FB}" => 'u',
            "\x{F1}" => 'n', "\x{E7}" => 'c',
            "\x{C0}" => 'A', "\x{C1}" => 'A', "\x{C2}" => 'A',
            "\x{C8}" => 'E', "\x{C9}" => 'E', "\x{CA}" => 'E', "\x{CB}" => 'E',
            "\x{CC}" => 'I', "\x{CD}" => 'I', "\x{CE}" => 'I', "\x{CF}" => 'I',
            "\x{D2}" => 'O', "\x{D3}" => 'O', "\x{D4}" => 'O',
            "\x{D9}" => 'U', "\x{DA}" => 'U', "\x{DB}" => 'U',
            "\x{D1}" => 'N', "\x{C7}" => 'C',
        },

        # ---------------------------------------------------------
        # ASCII transliteration pre-map — used BEFORE NFD in to_ascii().
        #
        # NFD handles automatically (no entry needed):
        #   à→a  á→a  â→a  è→e  é→e  ê→e  ì→i  í→i  î→i
        #   ò→o  ó→o  ô→o  ù→u  ú→u  û→u  ñ→n  ç→c  (and uppercase)
        #
        # German DIN 5007-1 exceptions — must be pre-mapped BEFORE NFD
        # because NFD would give ä→a (loses the -e suffix convention):
        #   ä → ae   ö → oe   ü → ue
        #   Ä → AE   Ö → OE   Ü → UE
        #   ß (U+00DF) — has no NFD decomposition → must map manually
        # ---------------------------------------------------------
        ascii_map => {
            "\x{E4}"  => 'ae',  "\x{C4}"  => 'AE',   # ä → ae, Ä → AE  (DIN 5007)
            "\x{F6}"  => 'oe',  "\x{D6}"  => 'OE',   # ö → oe, Ö → OE  (DIN 5007)
            "\x{FC}"  => 'ue',  "\x{DC}"  => 'UE',   # ü → ue, Ü → UE  (DIN 5007)
            "\x{DF}"  => 'ss',                         # ß → ss  (no NFD decomposition)
        },


        # ---------------------------------------------------------
        # num2text number words (German)
        # ---------------------------------------------------------
        numbers => {
            zero     => 'Null',
            ones     => [qw(Eins Zwei Drei Vier Fünf Sechs Sieben Acht Neun)],
            tens     => [qw(Zehn Zwanzig Dreißig Vierzig Fünfzig Sechzig Siebzig Achtzig Neunzig)],
            hundred  => 'Hundert',
            thousand => 'Tausend',
            million  => 'Million',
            billion  => 'Milliarde',
            currency => { main => 'EUR', sub => 'Cent' },
            decimal_sep => ',',
            thousand_one_prefix => 1,  # German: "ein Tausend" (unlike Turkish "Bin")
        },

        # ---------------------------------------------------------
        # Locale-specific HTML entity extras (German umlauts)
        # ---------------------------------------------------------
        html_entities => {
            '&auml;'  => "\x{E4}",  '&Auml;'  => "\x{C4}",  # ä, Ä
            '&ouml;'  => "\x{F6}",  '&Ouml;'  => "\x{D6}",  # ö, Ö
            '&uuml;'  => "\x{FC}",  '&Uuml;'  => "\x{DC}",  # ü, Ü
            '&szlig;' => "\x{DF}",                            # ß
        },

        # ---------------------------------------------------------
        # Month and Day names (German)
        # ---------------------------------------------------------
        months => [
            "Januar", "Februar", "März", "April", "Mai", "Juni",
            "Juli", "August", "September", "Oktober", "November", "Dezember"
        ],
        days => [
            "Sonntag", "Montag", "Dienstag", "Mittwoch",
            "Donnerstag", "Freitag", "Samstag"
        ],

        # ---------------------------------------------------------
        # Formatting metadata (number, currency, date, plural)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => ',',
            group_sep   => '.',
            group_size  => 3,
        },

        default_currency  => 'EUR',
        currency_position => 'suffix',
        currency_space    => 1,

        date_format => {
            short    => 'DD.MM.YYYY',
            medium   => 'D. MMM YYYY',
            long     => 'D. MMMM YYYY',
            full     => 'dddd, D. MMMM YYYY',
            time     => 'HH:mm',
            datetime => 'DD.MM.YYYY HH:mm',
        },

        plural_rule => 'one{n==1}other',
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::de - German Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('de');

=head1 DESCRIPTION

Provides German (de) casing, character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
