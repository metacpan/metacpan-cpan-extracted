package AmberDB::Locale::Lang::es;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-23';

# -------------------------------------------------------
# Spanish locale data for AmberDB::Locale.
# Pure data module — no logic.
# -------------------------------------------------------
sub data {
    return {
        uc_map => {},
        lc_map => {},

        regex_map => {
            'ñ' => '[ñÑ]', 'Ñ' => '[ñÑ]',
            'á' => '[áÁ]', 'Á' => '[áÁ]',
            'é' => '[éÉ]', 'É' => '[éÉ]',
            'í' => '[íÍ]', 'Í' => '[íÍ]',
            'ó' => '[óÓ]', 'Ó' => '[óÓ]',
            'ú' => '[úÚ]', 'Ú' => '[úÚ]',
            'ü' => '[üÜ]', 'Ü' => '[üÜ]',
        },
        phonetic_map => [
            [ 'd$' => 't' ],
        ],
        sort_map => {},

        # Characters allowed in Spanish text (normalize)
        alphabet_chars => "\x{E1}\x{C1}\x{E9}\x{C9}\x{ED}\x{CD}\x{F3}\x{D3}\x{FA}\x{DA}\x{FC}\x{DC}\x{F1}\x{D1}\x{BF}\x{A1}",
        #                   á      Á      é      É      í      Í      ó      Ó      ú      Ú      ü      Ü      ñ      Ñ      ¿      ¡

        accent_map => {},

        # ASCII transliteration pre-map (explicit ñ → n transliteration before NFD)
        ascii_map => {
            "\x{F1}" => 'n', "\x{D1}" => 'N',   # ñ → n, Ñ → N
        },

        # Spanish numbers (num2text)
        numbers => {
            zero     => 'Cero',
            ones     => [qw(Uno Dos Tres Cuatro Cinco Seis Siete Ocho Nueve)],
            tens     => [qw(Diez Veinte Treinta Cuarenta Cincuenta Sesenta Setenta Ochenta Noventa)],
            hundred  => 'Ciento',
            thousand => 'Mil',
            million  => 'Millón',
            billion  => 'Billón',
            currency => { main => 'EUR', sub => 'céntimo' },
            decimal_sep => ',',
            hundred_one_prefix  => 0,  # "Cien / Ciento" not "Uno Ciento"
            thousand_one_prefix => 0,  # "Mil" not "Uno Mil"
        },

        html_entities => {
            '&ntilde;' => "\x{F1}", '&Ntilde;' => "\x{D1}",
            '&aacute;' => "\x{E1}", '&Aacute;' => "\x{C1}",
            '&eacute;' => "\x{E9}", '&Eacute;' => "\x{C9}",
            '&iacute;' => "\x{ED}", '&Iacute;' => "\x{CD}",
            '&oacute;' => "\x{F3}", '&Oacute;' => "\x{D3}",
            '&uacute;' => "\x{FA}", '&Uacute;' => "\x{DA}",
        },

        # ---------------------------------------------------------
        # Month and Day names (Spanish)
        # ---------------------------------------------------------
        months => [
            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
        ],
        days => [
            "Domingo", "Lunes", "Martes", "Miércoles",
            "Jueves", "Viernes", "Sábado"
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
            short    => 'DD/MM/YYYY',
            medium   => 'D MMM YYYY',
            long     => 'D MMMM YYYY',
            full     => 'dddd, D MMMM YYYY',
            time     => 'HH:mm',
            datetime => 'DD/MM/YYYY HH:mm',
        },

        plural_rule => 'one{n==1}other',
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::es - Spanish Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('es');

=head1 DESCRIPTION

Provides Spanish (es) casing, character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
