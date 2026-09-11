package AmberDB::Locale::Lang::tr;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-22';

# -------------------------------------------------------
# Turkish locale data for AmberDB::Locale.
# Pure data module — no logic.
#
# Turkish-specific casing rules (dotted/dotless-I):
#   Lowercase:  I  → ı (U+0131)   dotless i
#               İ  → i            dotted I to i
#   Uppercase:  i  → İ (U+0130)   dotted I
#               (ı → I handled by Perl's uc() already)
# -------------------------------------------------------
sub data {
    return {

        # ---------------------------------------------------------
        # Casing special-cases (see Language.pm for usage)
        # uc_map: replacements applied BEFORE Perl's uc()
        # lc_map: replacements applied BEFORE Perl's lc()
        # ---------------------------------------------------------
        uc_map => {
            'i' => "\x{130}",    # Latin i → Turkish dotted İ (before uc)
        },
        lc_map => {
            'I'        => "\x{131}",  # Latin I → Turkish dotless ı
            "\x{130}"  => 'i',        # Turkish dotted İ → i
        },

        # ---------------------------------------------------------
        # Case-insensitive search regex character map
        # ---------------------------------------------------------
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
        },

        # Phonetic assimilation and final-devoicing rules
        phonetic_map => [
            [ 'b$'    => 'p'  ],
            [ 'd$'    => 't'  ],
            [ 'g$'    => 'k'  ],
        ],

        # ---------------------------------------------------------
        # Optional custom sort collation overrides.
        # Unicode::Collate::Locale handles standard collation automatically.
        # ---------------------------------------------------------
        sort_map => {},


        # ---------------------------------------------------------
        # Alphabet character class for normalize().
        # Characters that are considered valid letters in Turkish text.
        # Used inside a regex character class alongside a-zA-Z.
        # ---------------------------------------------------------
        alphabet_chars => "\x{E7}\x{C7}\x{11F}\x{11E}\x{131}I\x{130}\x{F6}\x{D6}\x{15F}\x{15E}\x{FC}\x{DC}",
        #                   ç      Ç      ğ      Ğ      ı    I  İ      ö      Ö      ş      Ş      ü      Ü

        # ---------------------------------------------------------
        # Accent normalization map — used by normalize().
        # Maps accented characters to the closest Turkish equivalent.
        # Note: î → i (not İ) since we are in text normalization,
        #       ô → ö (Turkish convention), etc.
        # ---------------------------------------------------------
        accent_map => {
            "\x{E2}" => 'a',         "\x{C2}" => 'A',   # â → a, Â → A
            "\x{E0}" => 'a',         "\x{C0}" => 'A',   # à → a, À → A
            "\x{E1}" => 'a',         "\x{C1}" => 'A',   # á → a, Á → A
            "\x{EA}" => 'e',         "\x{CA}" => 'E',   # ê → e, Ê → E
            "\x{E8}" => 'e',         "\x{C8}" => 'E',   # è → e, È → E
            "\x{E9}" => 'e',         "\x{C9}" => 'E',   # é → e, É → E
            "\x{EE}" => 'i',         "\x{CE}" => "\x{130}",  # î → i, Î → İ (Türkçe)
            "\x{EC}" => 'i',         "\x{CC}" => "\x{130}",  # ì → i, Ì → İ
            "\x{ED}" => 'i',         "\x{CD}" => "\x{130}",  # í → i, Í → İ
            "\x{F4}" => "\x{F6}",    "\x{D4}" => "\x{D6}",   # ô → ö, Ô → Ö (Türkçe)
            "\x{F2}" => 'o',         "\x{D2}" => 'O',   # ò → o, Ò → O
            "\x{F3}" => 'o',         "\x{D3}" => 'O',   # ó → o, Ó → O
            "\x{FB}" => 'u',         "\x{DB}" => 'U',   # û → u, Û → U
            "\x{F9}" => 'u',         "\x{D9}" => 'U',   # ù → u, Ù → U
            "\x{FA}" => 'u',         "\x{DA}" => 'U',   # ú → u, Ú → U
        },

        # ---------------------------------------------------------
        # ASCII transliteration pre-map — used BEFORE NFD in to_ascii().
        #
        # Only list chars that Unicode NFD cannot decompose automatically,
        # or chars that need language-specific transliteration different
        # from what NFD would produce.
        #
        # NFD handles automatically (no entry needed here):
        #   ç→c  ğ→g  ş→s  ö→o  ü→u  İ→I
        #   â→a  î→i  û→u  (and all other accented vowels)
        #
        # Exceptions for Turkish:
        #   ı (U+0131, dotless-i) — has no NFD decomposition → must map manually
        # ---------------------------------------------------------
        ascii_map => {
            "\x{131}" => 'i',   # ı (U+0131, dotless-i) — no NFD decomposition
        },


        # ---------------------------------------------------------
        # num2text number words (Turkish)
        # ones[0] = "Bir" (for 1), ones[8] = "Dokuz" (for 9)
        # ---------------------------------------------------------
        numbers => {
            zero     => 'Sıfır',
            negative => 'Eksi',
            ones     => [qw(Bir İki Üç Dört Beş Altı Yedi Sekiz Dokuz)],
            tens     => [qw(On Yirmi Otuz Kırk Elli Altmış Yetmiş Seksen Doksan)],
            hundred  => 'Yüz',
            thousand => 'Bin',
            million  => 'Milyon',
            billion  => 'Milyar',
            currency => { main => 'TL', sub => 'KR' },
            decimal_sep => ',',
            # Special rules: "Yüz" not "Bir Yüz", "Bin" not "Bir Bin"
            hundred_one_prefix  => 0,
            thousand_one_prefix => 0,
        },

        # ---------------------------------------------------------
        # Locale-specific HTML entity extras
        # ---------------------------------------------------------
        html_entities => {
            '&ccedil;' => "\x{E7}",   '&Ccedil;' => "\x{C7}",   # ç, Ç
            '&scedil;'  => "\x{15F}", '&Scedil;' => "\x{15E}",  # ş, Ş
            '&gbreve;'  => "\x{11F}", '&Gbreve;' => "\x{11E}",  # ğ, Ğ
            '&acirc;'   => "\x{E2}",  '&Acirc;'  => "\x{C2}",   # â, Â
            '&icirc;'   => "\x{EE}",  '&Icirc;'  => "\x{CE}",   # î, Î
            '&ucirc;'   => "\x{FB}",  '&Ucirc;'  => "\x{DB}",   # û, Û
            '&uuml;'    => "\x{FC}",  '&Uuml;'   => "\x{DC}",   # ü, Ü
            '&ouml;'    => "\x{F6}",  '&Ouml;'   => "\x{D6}",   # ö, Ö
        },

        # ---------------------------------------------------------
        # Month and Day names (Turkish)
        # ---------------------------------------------------------
        months => [
            "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
            "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
        ],
        days => [
            "Pazar", "Pazartesi", "Salı", "Çarşamba",
            "Perşembe", "Cuma", "Cumartesi"
        ],

        # ---------------------------------------------------------
        # Formatting metadata (number, currency, date, plural)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => ',',
            group_sep   => '.',
            group_size  => 3,
        },

        default_currency  => 'TRY',
        currency_position => 'prefix',
        currency_space    => 0,

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

AmberDB::Locale::Lang::tr - Turkish Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('tr');

=head1 DESCRIPTION

Provides Turkish (tr) casing (including dotted/dotless I rules: C<i -E<gt> İ>, C<ı -E<gt> I>), character maps, number/currency formats, date templates, phonetic devoicing (C<b/d/g -E<gt> p/t/k>), and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2005-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
