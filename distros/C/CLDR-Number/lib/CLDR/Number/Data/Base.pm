package CLDR::Number::Data::Base;

use v5.8.1;
use utf8;
use strict;
use warnings;
use charnames qw( :full );
use CLDR::Number::Constant qw( $N $M $P $C );

# This module does not have a publicly supported interface and may change in
# backward incompatible ways in the future. Please use one of the documented
# classes instead.

our $VERSION      = '0.19';
our $CLDR_VERSION = '29';

our $DATA = {
    root => {
        pattern => {
            at_least => '⩾{0}',
            currency => '¤ #,##0.00',
            decimal => '#,##0.###',
            percent => '#,##0%',
            range => '{0}–{1}',
        },
        symbol => {
            decimal => '.',
            group => ',',
            infinity => '∞',
            minus => '-',
            nan => 'NaN',
            percent => '%',
            permil => '‰',
            plus => '+',
        },
        attr => {
            min_group => 1,
            system => 'latn',
        },
    },
    af => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    agq => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    ak => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    am => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    ar => {
        pattern => {
            at_least => '+{0}',
        },
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{RIGHT-TO-LEFT MARK}-",
            nan => 'ليس رقم',
            percent => '٪',
            permil => '؉',
            plus => "\N{RIGHT-TO-LEFT MARK}+",
        },
        attr => {
            system => 'arab',
        },
    },
    'ar-DZ' => {
        symbol => {
            decimal => ',',
            group => '.',
            minus => "\N{LEFT-TO-RIGHT MARK}-",
            nan => 'ليس رقمًا',
            permil => '‰',
            plus => "\N{LEFT-TO-RIGHT MARK}+",
        },
        attr => {
            system => 'latn',
        },
    },
    'ar-EH' => {
        symbol => {
            decimal => '.',
            group => ',',
            minus => "\N{LEFT-TO-RIGHT MARK}-",
            nan => 'ليس رقمًا',
            permil => '‰',
            plus => "\N{LEFT-TO-RIGHT MARK}+",
        },
        attr => {
            system => 'latn',
        },
    },
    'ar-LY' => {
        symbol => {
            decimal => ',',
            group => '.',
            minus => "\N{LEFT-TO-RIGHT MARK}-",
            nan => 'ليس رقمًا',
            permil => '‰',
            plus => "\N{LEFT-TO-RIGHT MARK}+",
        },
        attr => {
            system => 'latn',
        },
    },
    'ar-MA' => {
        symbol => {
            decimal => ',',
            group => '.',
            minus => "\N{LEFT-TO-RIGHT MARK}-",
            nan => 'ليس رقمًا',
            permil => '‰',
            plus => "\N{LEFT-TO-RIGHT MARK}+",
        },
        attr => {
            system => 'latn',
        },
    },
    'ar-TN' => {
        symbol => {
            decimal => ',',
            group => '.',
            minus => "\N{LEFT-TO-RIGHT MARK}-",
            nan => 'ليس رقمًا',
            permil => '‰',
            plus => "\N{LEFT-TO-RIGHT MARK}+",
        },
        attr => {
            system => 'latn',
        },
    },
    as => {
        pattern => {
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
        attr => {
            system => 'beng',
        },
    },
    asa => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
    },
    ast => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
            nan => 'ND',
        },
    },
    az => {
        pattern => {
            at_least => '{0}+',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'az-Cyrl' => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    bas => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    be => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
        attr => {
            min_group => 2,
        },
    },
    bem => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    bez => {
        pattern => {
            currency => '#,##0.00¤',
        },
    },
    bg => {
        pattern => {
            at_least => '⩾ {0}',
            currency => '#,##0.00 ¤',
            range => '{0} – {1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
        attr => {
            min_group => 2,
        },
    },
    bm => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    bn => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##,##0.00¤',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
        symbol => {
            nan => 'সংখ্যা না',
        },
        attr => {
            system => 'beng',
        },
    },
    br => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    brx => {
        pattern => {
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
    },
    bs => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'bs-Cyrl' => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ca => {
        pattern => {
            at_least => '≥ {0}',
            currency => '#,##0.00 ¤',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ce => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            nan => 'Терхьаш дац',
        },
    },
    cgg => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    chr => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    ckb => {
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{RIGHT-TO-LEFT MARK}-",
            percent => '٪',
            permil => '؉',
            plus => "\N{RIGHT-TO-LEFT MARK}+",
        },
        attr => {
            system => 'arab',
        },
    },
    cs => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    cy => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    da => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    dav => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    de => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'de-AT' => {
        pattern => {
            currency => '¤ #,##0.00',
        },
        symbol => {
            group => ' ',
        },
    },
    'de-CH' => {
        pattern => {
            currency => '¤ #,##0.00;¤-#,##0.00',
            percent => '#,##0%',
        },
        symbol => {
            decimal => '.',
            group => q['],
        },
    },
    'de-LI' => {
        pattern => {
            currency => '¤ #,##0.00',
            percent => '#,##0%',
        },
        symbol => {
            decimal => '.',
            group => q['],
        },
    },
    dje => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            group => ' ',
        },
    },
    dsb => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    dua => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    dyo => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    dz => {
        pattern => {
            currency => '¤#,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0 %',
        },
        symbol => {
            infinity => 'གྲངས་མེད',
            nan => 'ཨང་མད',
        },
        attr => {
            system => 'tibt',
        },
    },
    ebu => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    ee => {
        pattern => {
            currency => '¤#,##0.00',
        },
        symbol => {
            nan => 'mnn',
        },
    },
    el => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    en => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    'en-150' => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'en-AT' => {
        pattern => {
            currency => '¤ #,##0.00',
            percent => '#,##0 %',
        },
    },
    'en-BE' => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'en-CH' => {
        pattern => {
            currency => '¤ #,##0.00;¤-#,##0.00',
        },
    },
    'en-DE' => {
        pattern => {
            percent => '#,##0 %',
        },
    },
    'en-DK' => {
        pattern => {
            percent => '#,##0 %',
        },
    },
    'en-FI' => {
        pattern => {
            percent => '#,##0 %',
        },
        symbol => {
            group => ' ',
        },
    },
    'en-IN' => {
        pattern => {
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
    },
    'en-NL' => {
        pattern => {
            currency => '¤ #,##0.00;¤ -#,##0.00',
        },
    },
    'en-SE' => {
        pattern => {
            percent => '#,##0 %',
        },
        symbol => {
            group => ' ',
        },
    },
    'en-US-u-va-posix' => {
        pattern => {
            currency => '¤ #0.00',
            decimal => '#0.######',
            percent => '#0%',
        },
        symbol => {
            infinity => 'INF',
            permil => '0/00',
        },
    },
    'en-ZA' => {
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    eo => {
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    es => {
        pattern => {
            at_least => 'Más de {0}',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
        attr => {
            min_group => 2,
        },
    },
    'es-419' => {
        pattern => {
            currency => '¤#,##0.00',
        },
        symbol => {
            decimal => '.',
            group => ',',
        },
        attr => {
            min_group => 1,
        },
    },
    'es-AR' => {
        pattern => {
            currency => '¤ #,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'es-BO' => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'es-CL' => {
        pattern => {
            currency => '¤#,##0.00;¤-#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'es-CO' => {
        pattern => {
            currency => '¤ #,##0.00',
            percent => '#,##0%',
            range => 'de {0} a {1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'es-CR' => {
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    'es-DO' => {
        pattern => {
            percent => '#,##0%',
        },
    },
    'es-EC' => {
        pattern => {
            currency => '¤#,##0.00;¤-#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'es-GQ' => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    'es-GT' => {
        pattern => {
            range => '{0} al {1}',
        },
    },
    'es-MX' => {
        pattern => {
            percent => '#,##0%',
        },
    },
    'es-PY' => {
        pattern => {
            currency => '¤ #,##0.00;¤ -#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'es-UY' => {
        pattern => {
            currency => '¤ #,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'es-VE' => {
        pattern => {
            currency => '¤#,##0.00;¤-#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    et => {
        pattern => {
            currency => '#,##0.00 ¤',
            range => '{0}‒{1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
        },
        attr => {
            min_group => 2,
        },
    },
    eu => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '% #,##0',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ewo => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    fa => {
        pattern => {
            at_least => "\N{LEFT-TO-RIGHT MARK}{0}+\N{LEFT-TO-RIGHT MARK}",
            currency => "\N{LEFT-TO-RIGHT MARK}¤#,##0.00",
            range => '{0} تا {1}',
        },
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{LEFT-TO-RIGHT MARK}−",
            nan => 'ناعدد',
            percent => '٪',
            permil => '؉',
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    ff => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    fi => {
        pattern => {
            at_least => 'vähintään {0}',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0}‒{1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
            nan => 'epäluku',
        },
    },
    fil => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            range => '{0}-{1}',
        },
    },
    fo => {
        pattern => {
            at_least => '{0} ella meira',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => '.',
            minus => '−',
        },
    },
    fr => {
        pattern => {
            at_least => 'au moins {0}',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    'fr-BE' => {
        symbol => {
            group => '.',
        },
    },
    'fr-CH' => {
        pattern => {
            currency => '¤ #,##0.00;¤-#,##0.00',
            percent => '#,##0%',
        },
        symbol => {
            decimal => '.',
        },
    },
    'fr-LU' => {
        symbol => {
            group => '.',
        },
    },
    'fr-MA' => {
        symbol => {
            group => '.',
        },
    },
    fur => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    fy => {
        pattern => {
            at_least => '{0}+',
            currency => '¤ #,##0.00;¤ #,##0.00-',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ga => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    gd => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    gl => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    gsw => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            group => '’',
            minus => '−',
        },
    },
    gu => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
            range => '{0}-{1}',
        },
    },
    guz => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    gv => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    haw => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    he => {
        pattern => {
            at_least => '⩾{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            minus => "\N{LEFT-TO-RIGHT MARK}-",
            plus => "\N{LEFT-TO-RIGHT MARK}+",
        },
    },
    hi => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
    },
    hr => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    hsb => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    hu => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    hy => {
        pattern => {
            at_least => '{0}+',
            decimal => '#0.###',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    id => {
        pattern => {
            currency => '¤#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ig => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    is => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    it => {
        pattern => {
            currency => '#,##0.00 ¤',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'it-CH' => {
        pattern => {
            currency => '¤ #,##0.00;¤-#,##0.00',
        },
        symbol => {
            decimal => '.',
            group => q['],
        },
    },
    ja => {
        pattern => {
            at_least => '{0} 以上',
            currency => '¤#,##0.00',
            range => '{0}～{1}',
        },
    },
    jgo => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    jmc => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    ka => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            nan => 'არ არის რიცხვი',
        },
        attr => {
            min_group => 2,
        },
    },
    kab => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    kam => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    kde => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    kea => {
        pattern => {
            at_least => '+{0}',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    khq => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            group => ' ',
        },
    },
    ki => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    kk => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    kkj => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    kl => {
        pattern => {
            currency => '¤#,##0.00;¤-#,##0.00',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    kln => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    km => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    kn => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    ko => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            range => '{0}~{1}',
        },
    },
    kok => {
        pattern => {
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
    },
    ks => {
        pattern => {
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{LEFT-TO-RIGHT MARK}-\N{LEFT-TO-RIGHT MARK}",
            percent => '٪',
            permil => '؉',
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    ksb => {
        pattern => {
            currency => '#,##0.00¤',
        },
    },
    ksf => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    ksh => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
            nan => '¤¤¤',
        },
    },
    kw => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    ky => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            nan => 'сан эмес',
        },
    },
    lb => {
        pattern => {
            at_least => '⩾ {0}',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    lg => {
        pattern => {
            currency => '#,##0.00¤',
        },
    },
    ln => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    lo => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00;¤-#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
            nan => "ບໍ່\N{ZERO WIDTH SPACE}ແມ່ນ\N{ZERO WIDTH SPACE}ໂຕ\N{ZERO WIDTH SPACE}ເລກ",
        },
    },
    lrc => {
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{LEFT-TO-RIGHT MARK}-\N{LEFT-TO-RIGHT MARK}",
            percent => '٪',
            permil => '؉',
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    lt => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
        },
    },
    lu => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    luo => {
        pattern => {
            currency => '#,##0.00¤',
        },
    },
    luy => {
        pattern => {
            currency => '¤#,##0.00;¤- #,##0.00',
        },
    },
    lv => {
        pattern => {
            at_least => 'vismaz {0}',
            currency => '#0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            nan => 'nav skaitlis',
        },
        attr => {
            min_group => 3,
        },
    },
    mas => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    mer => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    mfe => {
        symbol => {
            group => ' ',
        },
    },
    mg => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    mgh => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    mk => {
        pattern => {
            at_least => '{0}+',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ml => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            decimal => '#,##,##0.###',
            range => '{0}-{1}',
        },
    },
    mn => {
        pattern => {
            at_least => '{0}+',
        },
    },
    mr => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            decimal => '#,##,##0.###',
        },
        attr => {
            system => 'deva',
        },
    },
    ms => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    'ms-BN' => {
        pattern => {
            currency => '¤ #,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    mt => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    mua => {
        pattern => {
            currency => '¤#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    my => {
        symbol => {
            nan => 'ဂဏန်းမဟုတ်သော',
        },
        attr => {
            min_group => 3,
            system => 'mymr',
        },
    },
    mzn => {
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{LEFT-TO-RIGHT MARK}-\N{LEFT-TO-RIGHT MARK}",
            percent => '٪',
            permil => '؉',
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    naq => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    nb => {
        pattern => {
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
        },
    },
    nd => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    ne => {
        pattern => {
            at_least => '{0}+',
        },
        attr => {
            system => 'deva',
        },
    },
    nl => {
        pattern => {
            at_least => '{0}+',
            currency => '¤ #,##0.00;¤ -#,##0.00',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'nl-BE' => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
    },
    nmg => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    nn => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
        },
    },
    nnh => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    nus => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    nyn => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    om => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    or => {
        pattern => {
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
    },
    os => {
        symbol => {
            decimal => ',',
            group => ' ',
            nan => 'НН',
        },
    },
    pa => {
        pattern => {
            at_least => '{0}+',
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
    },
    'pa-Arab' => {
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{LEFT-TO-RIGHT MARK}-\N{LEFT-TO-RIGHT MARK}",
            percent => '٪',
            permil => '؉',
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    pl => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
        attr => {
            min_group => 2,
        },
    },
    ps => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{LEFT-TO-RIGHT MARK}-\N{LEFT-TO-RIGHT MARK}",
            percent => '٪',
            permil => '؉',
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    pt => {
        pattern => {
            at_least => '+{0}',
            currency => '¤#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'pt-PT' => {
        pattern => {
            currency => '#,##0.00 ¤',
            range => '{0} - {1}',
        },
        symbol => {
            group => ' ',
        },
        attr => {
            min_group => 2,
        },
    },
    qu => {
        pattern => {
            percent => '#,##0 %',
        },
    },
    'qu-BO' => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    rm => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            group => '’',
            minus => '−',
        },
    },
    rn => {
        pattern => {
            currency => '#,##0.00¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ro => {
        pattern => {
            at_least => '>{0}',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0} - {1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    rof => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    ru => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            nan => 'не число',
        },
    },
    rw => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    rwk => {
        pattern => {
            currency => '#,##0.00¤',
        },
    },
    saq => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    sbp => {
        pattern => {
            currency => '#,##0.00¤',
        },
    },
    se => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
            nan => '¤¤¤',
        },
    },
    seh => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ses => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            group => ' ',
        },
    },
    sg => {
        pattern => {
            currency => '¤#,##0.00;¤-#,##0.00',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    shi => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    'shi-Latn' => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    si => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    sk => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0} – {1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    sl => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    smn => {
        pattern => {
            at_least => 'ucemustáá {0}',
        },
        symbol => {
            nan => 'epiloho',
        },
    },
    sn => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    so => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    sq => {
        pattern => {
            at_least => '>{0}',
            currency => '#,##0.00 ¤',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    sr => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    'sr-Latn' => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    sv => {
        pattern => {
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
            range => '{0}‒{1}',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            minus => '−',
            nan => '¤¤¤',
        },
    },
    sw => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    'sw-CD' => {
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    ta => {
        pattern => {
            at_least => '{0}+',
            currency => '¤ #,##,##0.00',
            decimal => '#,##,##0.###',
            percent => '#,##,##0%',
        },
    },
    'ta-MY' => {
        pattern => {
            currency => '¤ #,##0.00',
            decimal => '#,##0.###',
            percent => '#,##0%',
        },
    },
    'ta-SG' => {
        pattern => {
            currency => '¤ #,##0.00',
            decimal => '#,##0.###',
            percent => '#,##0%',
        },
    },
    te => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##,##0.00',
            decimal => '#,##,##0.###',
        },
    },
    teo => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    th => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            range => '{0}-{1}',
        },
    },
    ti => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    tk => {
        pattern => {
            at_least => '≥{0}',
            currency => '#,##0.00 ¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            nan => 'san däl',
        },
    },
    to => {
        pattern => {
            at_least => '{0}+',
            range => '{0}—{1}',
        },
        symbol => {
            nan => 'TF',
        },
    },
    tr => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
            percent => '%#,##0',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    twq => {
        pattern => {
            currency => '#,##0.00¤',
        },
        symbol => {
            group => ' ',
        },
    },
    tzm => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    ug => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    uk => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    ur => {
        pattern => {
            currency => '¤ #,##,##0.00',
            percent => '#,##,##0%',
        },
        symbol => {
            minus => "\N{LEFT-TO-RIGHT MARK}-",
            plus => "\N{LEFT-TO-RIGHT MARK}+",
        },
    },
    'ur-IN' => {
        symbol => {
            minus => "\N{LEFT-TO-RIGHT MARK}-\N{LEFT-TO-RIGHT MARK}",
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    uz => {
        pattern => {
            at_least => '{0}+',
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
            nan => 'haqiqiy son emas',
        },
    },
    'uz-Arab' => {
        symbol => {
            decimal => '٫',
            group => '٬',
            minus => "\N{LEFT-TO-RIGHT MARK}-\N{LEFT-TO-RIGHT MARK}",
            percent => '٪',
            permil => '؉',
            plus => "\N{LEFT-TO-RIGHT MARK}+\N{LEFT-TO-RIGHT MARK}",
        },
        attr => {
            system => 'arabext',
        },
    },
    'uz-Cyrl' => {
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    vai => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    'vai-Latn' => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    vi => {
        pattern => {
            at_least => '{0}+',
            range => '{0}-{1}',
        },
        symbol => {
            decimal => ',',
            group => '.',
        },
    },
    vun => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    wae => {
        symbol => {
            decimal => ',',
            group => '’',
        },
    },
    xog => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
    },
    yav => {
        pattern => {
            currency => '#,##0.00 ¤',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    yo => {
        pattern => {
            currency => '¤#,##0.00',
        },
    },
    yue => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            range => '{0}-{1}',
        },
        symbol => {
            nan => '非數值',
        },
    },
    zgh => {
        pattern => {
            currency => '#,##0.00¤',
            percent => '#,##0 %',
        },
        symbol => {
            decimal => ',',
            group => ' ',
        },
    },
    zh => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            range => '{0}-{1}',
        },
    },
    'zh-Hant' => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
            range => '{0}-{1}',
        },
        symbol => {
            nan => '非數值',
        },
    },
    zu => {
        pattern => {
            at_least => '{0}+',
            currency => '¤#,##0.00',
        },
    },
    map { $_ => undef } qw(
        af-NA ar-AE ar-BH ar-DJ ar-EG ar-ER ar-IL ar-IQ ar-JO ar-KM ar-KW ar-LB
        ar-MR ar-OM ar-PS ar-QA ar-SA ar-SD ar-SO ar-SS ar-SY ar-TD ar-YE
        az-Latn bn-IN bo bo-IN bs-Latn ca-AD ca-ES-u-va-valencia ca-FR ca-IT
        ckb-IR cu da-GL de-BE de-LU ee-TG el-CY en-001 en-AG en-AI en-AS en-AU
        en-BB en-BI en-BM en-BS en-BW en-BZ en-CA en-CC en-CK en-CM en-CX en-CY
        en-DG en-DM en-ER en-FJ en-FK en-FM en-GB en-GD en-GG en-GH en-GI en-GM
        en-GU en-GY en-HK en-IE en-IL en-IM en-IO en-JE en-JM en-KE en-KI en-KN
        en-KY en-LC en-LR en-LS en-MG en-MH en-MO en-MP en-MS en-MT en-MU en-MW
        en-MY en-NA en-NF en-NG en-NR en-NU en-NZ en-PG en-PH en-PK en-PN en-PR
        en-PW en-RW en-SB en-SC en-SD en-SG en-SH en-SI en-SL en-SS en-SX en-SZ
        en-TC en-TK en-TO en-TT en-TV en-TZ en-UG en-UM en-VC en-VG en-VI en-VU
        en-WS en-ZM en-ZW es-BR es-CU es-EA es-HN es-IC es-NI es-PA es-PE es-PH
        es-PR es-SV es-US fa-AF ff-CM ff-GN ff-MR fo-DK fr-BF fr-BI fr-BJ fr-BL
        fr-CA fr-CD fr-CF fr-CG fr-CI fr-CM fr-DJ fr-DZ fr-GA fr-GF fr-GN fr-GP
        fr-GQ fr-HT fr-KM fr-MC fr-MF fr-MG fr-ML fr-MQ fr-MR fr-MU fr-NC fr-NE
        fr-PF fr-PM fr-RE fr-RW fr-SC fr-SN fr-SY fr-TD fr-TG fr-TN fr-VU fr-WF
        fr-YT gsw-FR gsw-LI ha ha-GH ha-NE hr-BA ii it-SM ko-KP lag lkt ln-AO
        ln-CF ln-CG lrc-IQ mas-TZ mgo ms-SG nb-SJ ne-IN nl-AW nl-BQ nl-CW nl-SR
        nl-SX om-KE os-RU pa-Guru prg pt-AO pt-CH pt-CV pt-GQ pt-GW pt-LU pt-MO
        pt-MZ pt-ST pt-TL qu-EC ro-MD ru-BY ru-KG ru-KZ ru-MD ru-UA sah se-FI
        se-SE shi-Tfng so-DJ so-ET so-KE sq-MK sq-XK sr-Cyrl sr-Cyrl-BA
        sr-Cyrl-ME sr-Cyrl-XK sr-Latn-BA sr-Latn-ME sr-Latn-XK sv-AX sv-FI sw-KE
        sw-UG ta-LK teo-KE ti-ER tr-CY uz-Latn vai-Vaii vo yi yo-BJ zh-Hans
        zh-Hans-HK zh-Hans-MO zh-Hans-SG zh-Hant-HK zh-Hant-MO
    )
};

our $PARENT = {
    'az-Arab' => 'root',
    'az-Cyrl' => 'root',
    'bm-Nkoo' => 'root',
    'bs-Cyrl' => 'root',
    'en-Dsrt' => 'root',
    'en-Shaw' => 'root',
    'ha-Arab' => 'root',
    'iu-Latn' => 'root',
    'mn-Mong' => 'root',
    'ms-Arab' => 'root',
    'pa-Arab' => 'root',
    'shi-Latn' => 'root',
    'sr-Latn' => 'root',
    'uz-Arab' => 'root',
    'uz-Cyrl' => 'root',
    'vai-Latn' => 'root',
    'yue-Hans' => 'root',
    'zh-Hant' => 'root',
    'en-150' => 'en-001',
    'en-AG' => 'en-001',
    'en-AI' => 'en-001',
    'en-AU' => 'en-001',
    'en-BB' => 'en-001',
    'en-BE' => 'en-001',
    'en-BM' => 'en-001',
    'en-BS' => 'en-001',
    'en-BW' => 'en-001',
    'en-BZ' => 'en-001',
    'en-CA' => 'en-001',
    'en-CC' => 'en-001',
    'en-CK' => 'en-001',
    'en-CM' => 'en-001',
    'en-CX' => 'en-001',
    'en-CY' => 'en-001',
    'en-DG' => 'en-001',
    'en-DM' => 'en-001',
    'en-ER' => 'en-001',
    'en-FJ' => 'en-001',
    'en-FK' => 'en-001',
    'en-FM' => 'en-001',
    'en-GB' => 'en-001',
    'en-GD' => 'en-001',
    'en-GG' => 'en-001',
    'en-GH' => 'en-001',
    'en-GI' => 'en-001',
    'en-GM' => 'en-001',
    'en-GY' => 'en-001',
    'en-HK' => 'en-001',
    'en-IE' => 'en-001',
    'en-IL' => 'en-001',
    'en-IM' => 'en-001',
    'en-IN' => 'en-001',
    'en-IO' => 'en-001',
    'en-JE' => 'en-001',
    'en-JM' => 'en-001',
    'en-KE' => 'en-001',
    'en-KI' => 'en-001',
    'en-KN' => 'en-001',
    'en-KY' => 'en-001',
    'en-LC' => 'en-001',
    'en-LR' => 'en-001',
    'en-LS' => 'en-001',
    'en-MG' => 'en-001',
    'en-MO' => 'en-001',
    'en-MS' => 'en-001',
    'en-MT' => 'en-001',
    'en-MU' => 'en-001',
    'en-MW' => 'en-001',
    'en-MY' => 'en-001',
    'en-NA' => 'en-001',
    'en-NF' => 'en-001',
    'en-NG' => 'en-001',
    'en-NR' => 'en-001',
    'en-NU' => 'en-001',
    'en-NZ' => 'en-001',
    'en-PG' => 'en-001',
    'en-PH' => 'en-001',
    'en-PK' => 'en-001',
    'en-PN' => 'en-001',
    'en-PW' => 'en-001',
    'en-RW' => 'en-001',
    'en-SB' => 'en-001',
    'en-SC' => 'en-001',
    'en-SD' => 'en-001',
    'en-SG' => 'en-001',
    'en-SH' => 'en-001',
    'en-SL' => 'en-001',
    'en-SS' => 'en-001',
    'en-SX' => 'en-001',
    'en-SZ' => 'en-001',
    'en-TC' => 'en-001',
    'en-TK' => 'en-001',
    'en-TO' => 'en-001',
    'en-TT' => 'en-001',
    'en-TV' => 'en-001',
    'en-TZ' => 'en-001',
    'en-UG' => 'en-001',
    'en-VC' => 'en-001',
    'en-VG' => 'en-001',
    'en-VU' => 'en-001',
    'en-WS' => 'en-001',
    'en-ZA' => 'en-001',
    'en-ZM' => 'en-001',
    'en-ZW' => 'en-001',
    'en-AT' => 'en-150',
    'en-CH' => 'en-150',
    'en-DE' => 'en-150',
    'en-DK' => 'en-150',
    'en-FI' => 'en-150',
    'en-NL' => 'en-150',
    'en-SE' => 'en-150',
    'en-SI' => 'en-150',
    'es-AR' => 'es-419',
    'es-BO' => 'es-419',
    'es-BR' => 'es-419',
    'es-CL' => 'es-419',
    'es-CO' => 'es-419',
    'es-CR' => 'es-419',
    'es-CU' => 'es-419',
    'es-DO' => 'es-419',
    'es-EC' => 'es-419',
    'es-GT' => 'es-419',
    'es-HN' => 'es-419',
    'es-MX' => 'es-419',
    'es-NI' => 'es-419',
    'es-PA' => 'es-419',
    'es-PE' => 'es-419',
    'es-PR' => 'es-419',
    'es-PY' => 'es-419',
    'es-SV' => 'es-419',
    'es-US' => 'es-419',
    'es-UY' => 'es-419',
    'es-VE' => 'es-419',
    'pt-AO' => 'pt-PT',
    'pt-CH' => 'pt-PT',
    'pt-CV' => 'pt-PT',
    'pt-GQ' => 'pt-PT',
    'pt-GW' => 'pt-PT',
    'pt-LU' => 'pt-PT',
    'pt-MO' => 'pt-PT',
    'pt-MZ' => 'pt-PT',
    'pt-ST' => 'pt-PT',
    'pt-TL' => 'pt-PT',
    'zh-Hant-MO' => 'zh-Hant-HK',
};

our $CACHE = {
    pattern => {
        '#0%'                         => [ '#0',          "$N$P"             ],
        '#,##0%'                      => [ '#,##0',       "$N$P"             ],
        '#,##0 %'                     => [ '#,##0',       "$N $P"            ],
        '#,##,##0%'                   => [ '#,##,##0',    "$N$P"             ],
        '#,##,##0 %'                  => [ '#,##,##0',    "$N $P"            ],
        '%#,##0'                      => [ '#,##0',       "$P$N"             ],
        '% #,##0'                     => [ '#,##0',       "$P $N"            ],
        '#0.00 ¤'                     => [ '#0.00',       "$N $C"            ],
        '#,##0.00¤'                   => [ '#,##0.00',    "$N$C"             ],
        '#,##0.00 ¤'                  => [ '#,##0.00',    "$N $C"            ],
        '#,##,##0.00¤'                => [ '#,##,##0.00', "$N$C"             ],
        '#,##,##0.00¤;(#,##,##0.00¤)' => [ '#,##,##0.00', "$N$C",  "($N$C)"  ],
        '¤#0.00'                      => [ '#0.00',       "$C$N"             ],
        '¤#,##0.00'                   => [ '#,##0.00',    "$C$N"             ],
        '¤#,##0.00;¤-#,##0.00'        => [ '#,##0.00',    "$C$N",  "$C$M$N"  ],
        '¤#,##0.00;¤- #,##0.00'       => [ '#,##0.00',    "$C$N",  "$C$M $N" ],
        '¤#,##0.00;(¤#,##0.00)'       => [ '#,##0.00',    "$C$N",  "($C$N)"  ],
        '¤#,##,##0.00'                => [ '#,##,##0.00', "$C$N"             ],
        '¤ #0.00'                     => [ '#0.00',       "$C $N"            ],
        '¤ #,##0.00'                  => [ '#,##0.00',    "$C $N"            ],
        '¤ #,##0.00;¤-#,##0.00'       => [ '#,##0.00',    "$C $N", "$C$M$N"  ],
        '¤ #,##0.00;¤ -#,##0.00'      => [ '#,##0.00',    "$C $N", "$C $M$N" ],
        '¤ #,##0.00;¤ #,##0.00-'      => [ '#,##0.00',    "$C $N", "$C $N$M" ],
        '¤ #,##,##0.00'               => [ '#,##,##0.00', "$C $N"            ],
        "\N{LEFT-TO-RIGHT EMBEDDING}#,##0%\N{POP DIRECTIONAL FORMATTING}" => [
            '#,##0',
            "\N{LEFT-TO-RIGHT EMBEDDING}$N$P\N{POP DIRECTIONAL FORMATTING}"
        ],
        "¤#,##0.00\N{LEFT-TO-RIGHT MARK}" => [
            '#,##0.00',
            "$C$N\N{LEFT-TO-RIGHT MARK}"
        ],
        "\N{LEFT-TO-RIGHT MARK}¤#,##0.00" => [
            '#,##0.00',
            "\N{LEFT-TO-RIGHT MARK}$C$N"
        ],
    },
    attribute => {
        '#0' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 0,
            maximum_fraction_digits => 0,
            primary_grouping_size   => 0,
            secondary_grouping_size => 0,
            rounding_increment      => 0,
        },
        '#0.00' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 2,
            maximum_fraction_digits => 2,
            primary_grouping_size   => 0,
            secondary_grouping_size => 0,
            rounding_increment      => 0,
        },
        '#0.###' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 0,
            maximum_fraction_digits => 3,
            primary_grouping_size   => 0,
            secondary_grouping_size => 0,
            rounding_increment      => 0,
        },
        '#0.######' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 0,
            maximum_fraction_digits => 6,
            primary_grouping_size   => 0,
            secondary_grouping_size => 0,
            rounding_increment      => 0,
        },
        '#,##0' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 0,
            maximum_fraction_digits => 0,
            primary_grouping_size   => 3,
            secondary_grouping_size => 0,
            rounding_increment      => 0,
        },
        '#,##0.00' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 2,
            maximum_fraction_digits => 2,
            primary_grouping_size   => 3,
            secondary_grouping_size => 0,
            rounding_increment      => 0,
        },
        '#,##0.###' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 0,
            maximum_fraction_digits => 3,
            primary_grouping_size   => 3,
            secondary_grouping_size => 0,
            rounding_increment      => 0,
        },
        '#,##,##0' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 0,
            maximum_fraction_digits => 0,
            primary_grouping_size   => 3,
            secondary_grouping_size => 2,
            rounding_increment      => 0,
        },
        '#,##,##0.00' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 2,
            maximum_fraction_digits => 2,
            primary_grouping_size   => 3,
            secondary_grouping_size => 2,
            rounding_increment      => 0,
        },
        '#,##,##0.###' => {
            minimum_integer_digits  => 1,
            minimum_fraction_digits => 0,
            maximum_fraction_digits => 3,
            primary_grouping_size   => 3,
            secondary_grouping_size => 2,
            rounding_increment      => 0,
        },
    },
};

1;
