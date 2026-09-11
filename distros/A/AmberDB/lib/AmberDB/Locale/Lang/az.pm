package AmberDB::Locale::Lang::az;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-23';

# -------------------------------------------------------
# Azerbaijani locale data for AmberDB::Locale.
# Pure data module — no logic.
#
# Casing rules:
#   I → ı, İ → i, E → e, Ə → ə
# -------------------------------------------------------
sub data {
    return {
        uc_map => {
            'i'       => "\x{130}",  # i → İ
            "\x{259}" => "\x{18F}",  # ə → Ə
        },
        lc_map => {
            'I'       => "\x{131}",  # I → ı
            "\x{130}" => 'i',        # İ → i
            "\x{18F}" => "\x{259}",  # Ə → ə
            "\x{18E}" => "\x{259}",  # Ǝ → ə
        },

        regex_map => {
            'ç'       => '[çÇ]',
            'Ç'       => '[çÇ]',
            'ğ'       => '[ğĞ]',
            'Ğ'       => '[ğĞ]',
            'ı'       => '[ıI]',
            'I'       => '[ıI]',
            'i'       => '[iİ]',
            "\x{130}" => '[iİ]',
            'ö'       => '[öÖ]',
            'Ö'       => '[öÖ]',
            'ü'       => '[üÜ]',
            'Ü'       => '[üÜ]',
            'ş'       => '[şŞ]',
            'Ş'       => '[şŞ]',
            "\x{259}" => "[\x{259}\x{18F}]",
            "\x{18F}" => "[\x{259}\x{18F}]",
            "\x{18E}" => "[\x{259}\x{18F}]",
        },

        phonetic_map => [
            [ 'd[dt]' => 'tt' ],
            [ 'b$'    => 'p'  ],
            [ 'd$'    => 't'  ],
            [ 'g$'    => 'k'  ],
        ],
        sort_map => {},

        # Characters allowed in Azerbaijani text
        alphabet_chars => "\x{E7}\x{C7}\x{11F}\x{11E}\x{131}I\x{130}\x{F6}\x{D6}\x{15F}\x{15E}\x{FC}\x{DC}\x{259}\x{18F}",
        #                   ç      Ç      ğ      Ğ      ı    I  İ      ö      Ö      ş      Ş      ü      Ü      ə      Ə

        accent_map => {},

        # ASCII transliteration pre-map
        ascii_map => {
            "\x{259}" => 'e', "\x{18F}" => 'E', "\x{18E}" => 'E',   # ə → e, Ə → E
            "\x{131}" => 'i',                                         # ı → i
        },

        # Azerbaijani numbers (num2text)
        numbers => {
            zero     => 'Sıfır',
            ones     => [qw(Bir İki Üç Dörd Beş Altı Yeddi Səkkiz Doqquz)],
            tens     => [qw(On İyirmi Otuz Qırx Əlli Altmış Yetmiş Səksən Doxsan)],
            hundred  => 'Yüz',
            thousand => 'Min',
            million  => 'Milyon',
            billion  => 'Milyard',
            currency => { main => 'AZN', sub => 'qəpik' },
            decimal_sep => ',',
            hundred_one_prefix  => 0,
            thousand_one_prefix => 0,
        },

        html_entities => {
            '&ccedil;' => "\x{E7}", '&Ccedil;' => "\x{C7}",
            '&gbreve;' => "\x{11F}", '&Gbreve;' => "\x{11E}",
            '&uuml;'    => "\x{FC}",  '&Uuml;'    => "\x{DC}",
            '&ouml;'    => "\x{F6}",  '&Ouml;'    => "\x{D6}",
        },

        # Month and Day names (Azerbaijani)
        # ---------------------------------------------------------
        months => [
            "Yanvar", "Fevral", "Mart", "Aprel", "May", "İyun",
            "İyul", "Avqust", "Sentyabr", "Oktyabr", "Noyabr", "Dekabr"
        ],
        days => [
            "Bazar", "Bazar ertəsi", "Çərşənbə axşamı", "Çərşənbə",
            "Cümə axşamı", "Cümə", "Şənbə"
        ],

        # ---------------------------------------------------------
        # Formatting metadata (number, currency, date, plural)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => ',',
            group_sep   => '.',
            group_size  => 3,
        },

        default_currency  => 'AZN',
        currency_position => 'suffix',
        currency_space    => 1,

        date_format => {
            short    => 'DD.MM.YYYY',
            medium   => 'D MMM YYYY',
            long     => 'D MMMM YYYY',
            full     => 'dddd, D MMMM YYYY',
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

AmberDB::Locale::Lang::az - Azerbaijani Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('az');

=head1 DESCRIPTION

Provides Azerbaijani (az) casing, character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
