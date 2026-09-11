package AmberDB::Locale::Lang::fr;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-23';

# -------------------------------------------------------
# French locale data for AmberDB::Locale.
# Pure data module — no logic.
# -------------------------------------------------------
sub data {
    return {
        uc_map => {},
        lc_map => {},

        regex_map => {
            'é' => '[éÉ]', 'É' => '[éÉ]',
            'è' => '[èÈ]', 'È' => '[èÈ]',
            'ê' => '[êÊ]', 'Ê' => '[êÊ]',
            'à' => '[àÀ]', 'À' => '[àÀ]',
            'ç' => '[çÇ]', 'Ç' => '[çÇ]',
            'ù' => '[ùÙ]', 'Ù' => '[ùÙ]',
            'î' => '[îÎ]', 'Î' => '[îÎ]',
            'ô' => '[ôÔ]', 'Ô' => '[ôÔ]',
            'ë' => '[ëË]', 'Ë' => '[ëË]',
            'ï' => '[ïÏ]', 'Ï' => '[ïÏ]',
            'ü' => '[üÜ]', 'Ü' => '[üÜ]',
        },
        phonetic_map => [
            [ 'es$' => 'e' ],
            [ 's$'  => ''  ],
            [ 'x$'  => ''  ],
        ],
        sort_map => {},

        # Characters allowed in French text (normalize)
        alphabet_chars => "\x{E0}\x{C0}\x{E2}\x{C2}\x{E6}\x{C6}\x{E7}\x{C7}\x{E8}\x{C8}\x{E9}\x{C9}\x{EA}\x{CA}\x{EB}\x{CB}\x{EE}\x{CE}\x{EF}\x{CF}\x{F4}\x{D4}\x{153}\x{152}\x{F9}\x{D9}\x{FB}\x{DB}\x{FC}\x{DC}\x{FF}\x{178}",

        # Foreign accents normalization map
        accent_map => {
            "\x{153}" => 'oe', "\x{152}" => 'OE',   # œ, Œ → oe
            "\x{E6}"  => 'ae', "\x{C6}"  => 'AE',   # æ, Æ → ae
        },

        # ASCII transliteration pre-map (NFD handles the rest)
        ascii_map => {
            "\x{153}" => 'oe', "\x{152}" => 'OE',   # œ, Œ → oe
            "\x{E6}"  => 'ae', "\x{C6}"  => 'AE',   # æ, Æ → ae
        },

        # French numbers (num2text)
        numbers => {
            zero     => 'Zéro',
            ones     => [qw(Un Deux Trois Quatre Cinq Six Sept Huit Neuf)],
            tens     => [qw(Dix Vingt Trente Quarante Cinquante Soixante Soixante-Dix Quatre-Vingt Quatre-Vingt-Dix)],
            hundred  => 'Cent',
            thousand => 'Mille',
            million  => 'Million',
            billion  => 'Milliard',
            currency => { main => 'EUR', sub => 'centime' },
            decimal_sep => ',',
            hundred_one_prefix  => 0,  # "Cent" not "Un Cent"
            thousand_one_prefix => 0,  # "Mille" not "Un Mille"
        },

        html_entities => {
            '&eacute;' => "\x{E9}", '&Eacute;' => "\x{C9}",
            '&egrave;' => "\x{E8}", '&Egrave;' => "\x{C8}",
            '&ecirc;'  => "\x{EA}", '&Ecirc;'  => "\x{CA}",
            '&ccedil;' => "\x{E7}", '&Ccedil;' => "\x{C7}",
            '&agrave;' => "\x{E0}", '&Agrave;' => "\x{C0}",
        },

        # Month and Day names (French)
        # ---------------------------------------------------------
        months => [
            "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
            "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
        ],
        days => [
            "Dimanche", "Lundi", "Mardi", "Mercredi",
            "Jeudi", "Vendredi", "Samedi"
        ],

        # ---------------------------------------------------------
        # Formatting metadata (number, currency, date, plural)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => ',',
            group_sep   => ' ',
            group_size  => 3,
        },

        default_currency  => 'EUR',
        currency_position => 'suffix',
        currency_space    => 1,

        date_format => {
            short    => 'DD/MM/YYYY',
            medium   => 'D MMM YYYY',
            long     => 'D MMMM YYYY',
            full     => 'dddd D MMMM YYYY',
            time     => 'HH:mm',
            datetime => 'DD/MM/YYYY HH:mm',
        },

        plural_rule => 'one{n<=1}other',
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::fr - French Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('fr');

=head1 DESCRIPTION

Provides French (fr) casing, character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
