use strict;
use warnings;
use utf8;

use Test::Fatal;
use Test::More 0.96;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

my @locale_codes = sort DateTime::Locale->codes;
my %locale_names = map { $_ => 1 } DateTime::Locale->names;
my %locale_codes = map { $_ => 1 } DateTime::Locale->codes;

# These are locales that are missing native name data in the JSON source
# files.
my %is_locale_without_native_data = map { $_ => 1 } qw( nds nds-DE nds-NL );

subtest( 'basic overall tests', \&basic_tests );
for my $code (@locale_codes) {
    subtest( "basic tests for $code", sub { test_one_locale($code) } );
}
subtest( 'root locale',                    \&check_root );
subtest( 'en locale',                      \&check_en );
subtest( 'en-GB locale',                   \&check_en_GB );
subtest( 'en-US locale',                   \&check_en_US );
subtest( 'en-US-POSIX locale',             \&check_en_US_POSIX );
subtest( 'es-ES locale',                   \&check_es_ES );
subtest( 'af locale',                      \&check_af );
subtest( 'C locales',                      \&check_C_locales );
subtest( 'DateTime::Language back-compat', \&check_DT_Lang );

done_testing();

sub basic_tests {
    ok( @locale_codes >= 240,   'Coverage looks complete' );
    ok( $locale_names{English}, q{Locale name 'English' found} );
    ok( $locale_codes{'ar-JO'}, q{Locale code 'ar-JO' found} );

    like(
        exception { DateTime::Locale->load('Does not exist') },
        qr/invalid/i,
        'invalid locale name/code to DateTime::Locale->load causes an error'
    );

    # This format (which is common on POSIX systems) should work.
    my $l = DateTime::Locale->load('en-US.LATIN-1');
    is( $l->code, 'en-US', 'code is en-US when loading en-US.LATIN-1' );

    is(
        DateTime::Locale->load('en_US_POSIX')->code,
        'en-US-POSIX',
        'underscores in code name are turned into dashes'
    );
}

sub test_one_locale {
    my $code = shift;

    my $locale;
    is(
        exception { $locale = DateTime::Locale->load($code) },
        undef,
        "no exception loading locale for $code"
    );

    isa_ok( $locale, 'DateTime::Locale::FromData' );

    return if $code eq 'root';

    is(
        $locale->code,
        $code,
        '$locale->code returns the code used to load the locale'
    );

    ok( length $locale->name, 'has a locale name' );

    unless ( $is_locale_without_native_data{$code} ) {
        ok(
            length $locale->native_name,
            'has a native locale name',
        );
    }

    for my $test (
        {
            locale_method => 'month_format_wide',
            count         => 12,
        }, {
            locale_method => 'month_format_abbreviated',
            count         => 12,
        }, {
            locale_method => 'day_format_wide',
            count         => 7,
        }, {
            locale_method => 'day_format_abbreviated',
            count         => 7,
        }, {
            locale_method => 'quarter_format_wide',
            count         => 4,
        }, {
            locale_method => 'quarter_format_abbreviated',
            count         => 4,
        }, {
            locale_method => 'quarter_format_narrow',
            count         => 4,
        }, {
            locale_method => 'am_pm_abbreviated',
            count         => 2,
        }, {
            locale_method => 'era_wide',
            count         => 2,
        }, {
            locale_method => 'era_abbreviated',
            count         => 2,
        }, {
            locale_method => 'era_narrow',
            count         => 2,
        },
    ) {
        check_array( locale => $locale, %{$test} );
    }

    # We can't actually expect these to be unique.
    is(
        scalar @{ $locale->day_format_narrow }, 7,
        '$locale->day_format_narrow returns 7 items'
    );
    is(
        scalar @{ $locale->month_format_narrow }, 12,
        '$locale->month_format_narrow returns 12 items'
    );
    is(
        scalar @{ $locale->day_stand_alone_narrow }, 7,
        '$locale->day_stand_alone_narrow returns 7 items'
    );
    is(
        scalar @{ $locale->month_stand_alone_narrow }, 12,
        '$locale->month_stand_alone_narrow returns 12 items'
    );

    check_formats( $locale, 'date_formats', 'date_format' );
    check_formats( $locale, 'time_formats', 'time_format' );
}

sub check_array {
    my %test = @_;

    my $locale_method = $test{locale_method};

    my %unique = map { $_ => 1 } @{ $test{locale}->$locale_method };

    is(
        keys %unique, $test{count},
        qq{'$locale_method' contains $test{count} unique items}
    );
}

sub check_formats {
    my ( $locale, $hash_func, $item_func ) = @_;

    my %unique = map { $_ => 1 } values %{ $locale->$hash_func };

    ok(
        keys %unique >= 1,
        qq{'$hash_func' contains at least 1 unique item}
    );

    foreach my $length (qw( full long medium short )) {
        my $method = $item_func . q{_} . $length;

        my $val = $locale->$method;

        if ( defined $val ) {
            delete $unique{$val};
        }
        else {
            Test::More::diag("locale returned undef for $method");
        }
    }

    is(
        keys %unique, 0,
        qq{data returned by '$hash_func' and '$item_func patterns' matches}
    );
}

sub check_root {
    my $locale = DateTime::Locale->load('root');

    my %tests = (
        day_format_wide             => [qw( Mon Tue Wed Thu Fri Sat Sun )],
        day_format_abbreviated      => [qw( Mon Tue Wed Thu Fri Sat Sun )],
        day_format_narrow           => [qw( M T W T F S S )],
        day_stand_alone_wide        => [qw( Mon Tue Wed Thu Fri Sat Sun )],
        day_stand_alone_abbreviated => [qw( Mon Tue Wed Thu Fri Sat Sun )],
        day_stand_alone_narrow      => [qw( M T W T F S S )],
        month_format_wide =>
            [qw( M01 M02 M03 M04 M05 M06 M07 M08 M09 M10 M11 M12 )],
        month_format_abbreviated =>
            [qw( M01 M02 M03 M04 M05 M06 M07 M08 M09 M10 M11 M12 )],
        month_format_narrow => [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )],
        month_stand_alone_wide =>
            [qw( M01 M02 M03 M04 M05 M06 M07 M08 M09 M10 M11 M12 )],
        month_stand_alone_abbreviated =>
            [qw( M01 M02 M03 M04 M05 M06 M07 M08 M09 M10 M11 M12 )],
        month_stand_alone_narrow        => [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )],
        quarter_format_wide             => [qw( Q1 Q2 Q3 Q4 )],
        quarter_format_abbreviated      => [qw( Q1 Q2 Q3 Q4 )],
        quarter_format_narrow           => [qw( 1 2 3 4 )],
        quarter_stand_alone_wide        => [qw( Q1 Q2 Q3 Q4 )],
        quarter_stand_alone_abbreviated => [qw( Q1 Q2 Q3 Q4 )],
        quarter_stand_alone_narrow      => [qw( 1 2 3 4 )],
        era_wide                        => [qw( BCE CE )],
        era_abbreviated                 => [qw( BCE CE )],
        era_narrow                      => [qw( BCE CE )],
        am_pm_abbreviated               => [qw( AM PM )],
        datetime_format_full            => 'y MMMM d, EEEE HH:mm:ss zzzz',
        datetime_format_long            => 'y MMMM d HH:mm:ss z',
        datetime_format_medium          => 'y MMM d HH:mm:ss',
        datetime_format_short           => 'y-MM-dd HH:mm',
        datetime_format_default         => 'y MMM d HH:mm:ss',
        glibc_datetime_format           => '%a %b %e %H:%M:%S %Y',
        glibc_date_format               => '%m/%d/%y',
        glibc_time_format               => '%H:%M:%S',
        first_day_of_week               => 1,
        prefers_24_hour_time            => 1,
    );

    test_data( $locale, %tests );

    my %formats = (
        Bh                  => 'h B',
        Bhm                 => 'h:mm B',
        Bhms                => 'h:mm:ss B',
        E                   => 'ccc',
        EBhm                => 'E h:mm B',
        EBhms               => 'E h:mm:ss B',
        EHm                 => 'E HH:mm',
        EHms                => 'E HH:mm:ss',
        Ed                  => 'd, E',
        Ehm                 => 'E h:mm a',
        Ehms                => 'E h:mm:ss a',
        Gy                  => 'G y',
        GyMMM               => 'G y MMM',
        GyMMMEd             => 'G y MMM d, E',
        GyMMMd              => 'G y MMM d',
        H                   => 'HH',
        Hm                  => 'HH:mm',
        Hms                 => 'HH:mm:ss',
        Hmsv                => 'HH:mm:ss v',
        Hmv                 => 'HH:mm v',
        M                   => 'L',
        MEd                 => 'MM-dd, E',
        MMM                 => 'LLL',
        MMMEd               => 'MMM d, E',
        'MMMMW-count-other' => q{'week' W 'of' MMMM},
        MMMMd               => 'MMMM d',
        MMMd                => 'MMM d',
        Md                  => 'MM-dd',
        d                   => 'd',
        h                   => 'h a',
        hm                  => 'h:mm a',
        hms                 => 'h:mm:ss a',
        hmsv                => 'h:mm:ss a v',
        hmv                 => 'h:mm a v',
        ms                  => 'mm:ss',
        y                   => 'y',
        yM                  => 'y-MM',
        yMEd                => 'y-MM-dd, E',
        yMMM                => 'y MMM',
        yMMMEd              => 'y MMM d, E',
        yMMMM               => 'y MMMM',
        yMMMd               => 'y MMM d',
        yMd                 => 'y-MM-dd',
        yQQQ                => 'y QQQ',
        yQQQQ               => 'y QQQQ',
        'yw-count-other'    => q{'week' w 'of' Y},
    );

    test_formats( $locale, %formats );
}

sub check_en {
    my $locale = DateTime::Locale->load('en');

    my %tests = (
        en_data(),
        name => 'English',
    );

    test_data( $locale, %tests );
}

sub check_en_GB {
    my $locale = DateTime::Locale->load('en_GB');

    my %tests = (
        en_data(),
        am_pm_abbreviated       => [ 'am', 'pm' ],
        first_day_of_week       => 1,
        name                    => 'English United Kingdom',
        native_name             => 'English United Kingdom',
        language                => 'English',
        native_language         => 'English',
        territory               => 'United Kingdom',
        native_territory        => 'United Kingdom',
        variant                 => undef,
        native_variant          => undef,
        language_code           => 'en',
        territory_code          => 'GB',
        variant_code            => undef,
        glibc_datetime_format   => '%a %d %b %Y %T %Z',
        glibc_date_format       => '%d/%m/%y',
        glibc_time_format       => '%T',
        datetime_format_default => 'd MMM y, HH:mm:ss',
    );

    test_data( $locale, %tests );

    my %formats = (
        Bh                  => 'h B',
        Bhm                 => 'h.mm B',
        Bhms                => 'h.mm.ss B',
        E                   => 'ccc',
        EBhm                => 'E, h.mm B',
        EBhms               => 'E, h.mm.ss B',
        EHm                 => 'E HH:mm',
        EHms                => 'E HH:mm:ss',
        Ed                  => 'E d',
        Ehm                 => 'E h:mm a',
        Ehms                => 'E h:mm:ss a',
        Gy                  => 'y G',
        GyMMM               => 'MMM y G',
        GyMMMEd             => 'E, d MMM y G',
        GyMMMd              => 'd MMM y G',
        H                   => 'HH',
        Hm                  => 'HH:mm',
        Hms                 => 'HH:mm:ss',
        Hmsv                => 'HH:mm:ss v',
        Hmv                 => 'HH:mm v',
        M                   => 'L',
        MEd                 => 'E dd/MM',
        MMM                 => 'LLL',
        MMMEd               => 'E d MMM',
        'MMMMW-count-one'   => q{'week' W 'of' MMMM},
        'MMMMW-count-other' => q{'week' W 'of' MMMM},
        MMMMd               => 'd MMMM',
        MMMd                => 'd MMM',
        MMdd                => 'dd/MM',
        Md                  => 'dd/MM',
        d                   => 'd',
        h                   => 'h a',
        hm                  => 'h:mm a',
        hms                 => 'h:mm:ss a',
        hmsv                => 'h:mm:ss a v',
        hmv                 => 'h:mm a v',
        ms                  => 'mm:ss',
        y                   => 'y',
        yM                  => 'MM/y',
        yMEd                => 'E, dd/MM/y',
        yMMM                => 'MMM y',
        yMMMEd              => 'E, d MMM y',
        yMMMM               => 'MMMM y',
        yMMMd               => 'd MMM y',
        yMd                 => 'dd/MM/y',
        yQQQ                => 'QQQ y',
        yQQQQ               => 'QQQQ y',
        'yw-count-one'      => q{'week' w 'of' Y},
        'yw-count-other'    => q{'week' w 'of' Y},
    );

    test_formats( $locale, %formats );
}

sub check_en_US {
    my $locale = DateTime::Locale->load('en_US');

    my %tests = (
        en_data(),
        first_day_of_week => 7,
    );

    test_data( $locale, %tests );
}

sub en_data {
    return (
        day_format_wide =>
            [qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday )],
        day_format_abbreviated => [qw( Mon Tue Wed Thu Fri Sat Sun )],
        day_format_narrow      => [qw( M T W T F S S )],
        day_stand_alone_wide =>
            [qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday )],
        day_stand_alone_abbreviated => [qw( Mon Tue Wed Thu Fri Sat Sun )],
        day_stand_alone_narrow      => [qw( M T W T F S S )],
        month_format_wide           => [
            qw( January February March April May June
                July August September October November December )
        ],
        month_format_abbreviated =>
            [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )],
        month_format_narrow    => [qw( J F M A M J J A S O N D )],
        month_stand_alone_wide => [
            qw( January February March April May June
                July August September October November December )
        ],
        month_stand_alone_abbreviated =>
            [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )],
        month_stand_alone_narrow => [qw( J F M A M J J A S O N D )],
        quarter_format_wide =>
            [ '1st quarter', '2nd quarter', '3rd quarter', '4th quarter' ],
        quarter_format_abbreviated => [qw( Q1 Q2 Q3 Q4 )],
        quarter_format_narrow      => [qw( 1 2 3 4 )],
        quarter_stand_alone_wide =>
            [ '1st quarter', '2nd quarter', '3rd quarter', '4th quarter' ],
        quarter_stand_alone_abbreviated => [qw( Q1 Q2 Q3 Q4 )],
        quarter_stand_alone_narrow      => [qw( 1 2 3 4 )],
        era_wide                        => [ 'Before Christ', 'Anno Domini' ],
        era_abbreviated                 => [qw( BC AD )],
        era_narrow                      => [qw( B A )],
        am_pm_abbreviated               => [qw( AM PM )],
        first_day_of_week               => 1,
    );
}

sub test_data {
    my $locale = shift;
    my %tests  = @_;

    for my $k ( sort keys %tests ) {
        my $desc = "$k for " . $locale->code;
        if ( ref $tests{$k} ) {
            is_deeply( $locale->$k, $tests{$k}, $desc );
        }
        else {
            is( $locale->$k, $tests{$k}, $desc );
        }
    }
}

sub test_formats {
    my $locale  = shift;
    my %formats = @_;

    for my $name ( keys %formats ) {
        is(
            $locale->format_for($name), $formats{$name},
            "Format for $name with " . $locale->code
        );
    }

    is_deeply(
        [ $locale->available_formats ],
        [ sort keys %formats ],
        'Available formats for ' . $locale->code . ' match what is expected'
    );
}

sub check_es_ES {
    my $locale = DateTime::Locale->load('es_ES');

    is( $locale->name,             'Spanish Spain',    'name' );
    is( $locale->native_name,      'español España', 'native_name' );
    is( $locale->language,         'Spanish',          'language' );
    is( $locale->native_language,  'español',         'native_language' );
    is( $locale->territory,        'Spain',            'territory' );
    is( $locale->native_territory, 'España',          'native_territory' );
    is( $locale->variant,          undef,              'variant' );
    is( $locale->native_variant,   undef,              'native_variant' );

    is( $locale->language_code,  'es',  'language_code' );
    is( $locale->territory_code, 'ES',  'territory_code' );
    is( $locale->variant_code,   undef, 'variant_code' );
}

sub check_af {
    my $locale = DateTime::Locale->load('af');

    is_deeply(
        $locale->month_format_abbreviated,
        [qw( Jan. Feb. Mrt. Apr. Mei Jun. Jul. Aug. Sep. Okt. Nov. Des. )],
        'month abbreviations for af use non-draft form'
    );

    is_deeply(
        $locale->month_format_narrow,
        [qw( J F M A M J J A S O N D )],
        'month narrows for af use draft form because that is the only form available'
    );
}

sub check_en_US_POSIX {
    my $locale = DateTime::Locale->load('en-US-POSIX');

    is( $locale->variant,        'Computer', 'variant' );
    is( $locale->native_variant, 'Computer', 'native_variant' );

    is( $locale->language_code,  'en',    'language_code' );
    is( $locale->territory_code, 'US',    'territory_code' );
    is( $locale->variant_code,   'POSIX', 'variant_code' );
}

sub check_C_locales {
    for my $code (qw( C C.ISO-8859-1 C.UTF-8 POSIX )) {
        my $locale = DateTime::Locale->load($code);
        is(
            $locale->code, 'en-US-POSIX',
            "$code is accepted as a locale code"
        );
    }
}

sub check_DT_Lang {
    my @old_names = qw(
        Austrian
        TigrinyaEthiopian
        TigrinyaEritrean
        Brazilian
        Portugese
    );

    foreach my $old (@old_names) {
        ok(
            DateTime::Locale->load($old),
            "backwards compatibility for $old"
        );
    }

    foreach my $old (qw( Gedeo Afar Sidama Tigre )) {
    SKIP:
        {
            skip
                'No CLDR data for some African languages included in DT::Language',
                1
                unless $locale_names{$old};

            ok(
                DateTime::Locale->load($old),
                "backwards compatibility for $old"
            );
        }
    }
}

