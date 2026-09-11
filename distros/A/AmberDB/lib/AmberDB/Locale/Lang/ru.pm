package AmberDB::Locale::Lang::ru;

use 5.016;
use warnings;
use utf8;

our $VERSION = '5.25.1';

my $CREATED  = '2026-07-23';

# -------------------------------------------------------
# Russian (Cyrillic) locale data for AmberDB::Locale.
# Pure data module — no logic.
# -------------------------------------------------------
sub data {
    return {
        uc_map => {},
        lc_map => {},

        regex_map => {
            "\x{0451}" => "[\x{0451}\x{0401}]",
            "\x{0401}" => "[\x{0451}\x{0401}]",
        },

        # Russian final-devoicing rules (Оглушение согласных)
        phonetic_map => [
            [ "\x{0431}\$" => "\x{043F}" ], # б → п
            [ "\x{0434}\$" => "\x{0442}" ], # д → т
            [ "\x{0433}\$" => "\x{043A}" ], # г → к
            [ "\x{0432}\$" => "\x{0444}" ], # в → ф
            [ "\x{0437}\$" => "\x{0441}" ], # з → с
            [ "\x{0436}\$" => "\x{0448}" ], # ж → ш
        ],
        sort_map => {},

        # Characters allowed in Russian text (Cyrillic Unicode range U+0400 to U+04FF)
        alphabet_chars => "\x{0400}-\x{04FF}",

        accent_map => {
            "\x{0401}" => "\x{0415}", "\x{0451}" => "\x{0435}", # Ё → Е, ё → е (Russian normalization)
        },

        # Cyrillic to Latin ASCII transliteration (GOST 7.79-2000 System B)
        ascii_map => {
            "\x{0410}" => 'A',  "\x{0430}" => 'a',   # А, а
            "\x{0411}" => 'B',  "\x{0431}" => 'b',   # Б, б
            "\x{0412}" => 'V',  "\x{0432}" => 'v',   # В, в
            "\x{0413}" => 'G',  "\x{0433}" => 'g',   # Г, г
            "\x{0414}" => 'D',  "\x{0434}" => 'd',   # Д, д
            "\x{0415}" => 'E',  "\x{0435}" => 'e',   # Е, е
            "\x{0401}" => 'Yo', "\x{0451}" => 'yo',  # Ё, ё
            "\x{0416}" => 'Zh', "\x{0436}" => 'zh',  # Ж, ж
            "\x{0417}" => 'Z',  "\x{0437}" => 'z',   # З, з
            "\x{0418}" => 'I',  "\x{0438}" => 'i',   # И, и
            "\x{0419}" => 'Y',  "\x{0439}" => 'y',   # Й, й
            "\x{041A}" => 'K',  "\x{043A}" => 'k',   # К, к
            "\x{041B}" => 'L',  "\x{043B}" => 'l',   # Л, л
            "\x{041C}" => 'M',  "\x{043C}" => 'm',   # М, м
            "\x{041D}" => 'N',  "\x{043D}" => 'n',   # Н, н
            "\x{041E}" => 'O',  "\x{043E}" => 'o',   # О, о
            "\x{041F}" => 'P',  "\x{043F}" => 'p',   # П, п
            "\x{0420}" => 'R',  "\x{0440}" => 'r',   # Р, р
            "\x{0421}" => 'S',  "\x{0441}" => 's',   # С, с
            "\x{0422}" => 'T',  "\x{0442}" => 't',   # Т, т
            "\x{0423}" => 'U',  "\x{0443}" => 'u',   # У, у
            "\x{0424}" => 'F',  "\x{0444}" => 'f',   # Ф, ф
            "\x{0425}" => 'Kh', "\x{0445}" => 'kh',  # Х, х
            "\x{0426}" => 'Ts', "\x{0446}" => 'ts',  # Ц, ц
            "\x{0427}" => 'Ch', "\x{0447}" => 'ch',  # Ч, ч
            "\x{0428}" => 'Sh', "\x{0448}" => 'sh',  # Ш, ш
            "\x{0429}" => 'Shch', "\x{0449}" => 'shch', # Щ, щ
            "\x{042A}" => '',   "\x{044A}" => '',    # Ъ, ъ (hard sign)
            "\x{042B}" => 'Y',  "\x{044B}" => 'y',   # Ы, ы
            "\x{042C}" => '',   "\x{044C}" => '',    # Ь, ь (soft sign)
            "\x{042D}" => 'E',  "\x{044D}" => 'e',   # Э, э
            "\x{042E}" => 'Yu', "\x{044E}" => 'yu',  # Ю, ю
            "\x{042F}" => 'Ya', "\x{044F}" => 'ya',  # Я, я
        },

        # Russian numbers (num2text)
        numbers => {
            zero     => 'Ноль',
            ones     => [qw(Один Два Три Четыре Пять Шесть Семь Восемь Девять)],
            tens     => [qw(Десять Двадцать Тридцать Сорок Пятьдесят Шестьдесят Семьдесят Восемьдесят Девяносто)],
            hundred  => 'Сто',
            thousand => 'Тысяча',
            million  => 'Миллион',
            billion  => 'Миллиард',
            currency => { main => 'RUB', sub => 'копейка' },
            decimal_sep => ',',
            hundred_one_prefix  => 0,  # "Сто" not "Один Сто"
            thousand_one_prefix => 0,  # "Тысяча" not "Один Тысяча"
        },

        html_entities => {},

        # Month and Day names (Russian)
        # ---------------------------------------------------------
        months => [
            "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
            "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
        ],
        days => [
            "Воскресенье", "Понедельник", "Вторник", "Среда",
            "Четверг", "Пятница", "Суббота"
        ],

        # ---------------------------------------------------------
        # Formatting metadata (number, currency, date, plural)
        # ---------------------------------------------------------
        number_format => {
            decimal_sep => ',',
            group_sep   => ' ',
            group_size  => 3,
        },

        default_currency  => 'RUB',
        currency_position => 'suffix',
        currency_space    => 1,

        date_format => {
            short    => 'DD.MM.YYYY',
            medium   => 'D MMM YYYY г.',
            long     => 'D MMMM YYYY г.',
            full     => 'dddd, D MMMM YYYY г.',
            time     => 'HH:mm',
            datetime => 'DD.MM.YYYY HH:mm',
        },

        plural_rule => 'one{n%10==1&&n%100!=11}few{n%10>=2&&n%10<=4&&(n%100<10||n%100>=20)}many{n%10==0||(n%10>=5&&n%10<=9)||(n%100>=11&&n%100<=14)}other',
    };
}

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale::Lang::ru - Russian Language Definition and Locale Data for AmberDB

=head1 SYNOPSIS

    use AmberDB::Locale;
    my $loc = AmberDB::Locale->new('ru');

=head1 DESCRIPTION

Provides Russian (ru) casing, character maps, number/currency formats, date templates, and plural rules for the AmberDB locale engine.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
