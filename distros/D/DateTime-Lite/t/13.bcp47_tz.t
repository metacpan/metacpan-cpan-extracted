#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/13.bcp47_tz.t
## Tests for BCP47 -u-tz- locale extension timezone inference
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
use_ok( 'DateTime::Lite::TimeZone' ) or BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );

# NOTE: BCP47 -u-tz- extension: timezone inferred from locale
subtest 'BCP47 -u-tz- inferred when no time_zone given' => sub
{
    my $dt = DateTime::Lite->new(
        year   => 2026,
        month  => 4,
        day    => 10,
        locale => 'he-IL-u-ca-hebrew-tz-jeruslm',
    );
    ok( defined( $dt ), 'new() succeeds with BCP47 tz locale, no explicit time_zone' );
    is( $dt->time_zone_long_name, 'Asia/Jerusalem',
        'timezone inferred as Asia/Jerusalem from -u-tz-jeruslm' );
};

# NOTE: explicit time_zone always takes priority over -u-tz-
subtest 'Explicit time_zone takes priority over -u-tz- extension' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 10,
        time_zone => 'Asia/Tokyo',
        locale    => 'he-IL-u-ca-hebrew-tz-jeruslm',
    );
    ok( defined( $dt ), 'new() succeeds with both time_zone and BCP47 tz locale' );
    is( $dt->time_zone_long_name, 'Asia/Tokyo',
        'explicit time_zone=Asia/Tokyo takes priority over -u-tz-jeruslm' );
};

# NOTE: now() also benefits from -u-tz- inference
subtest 'now() infers timezone from -u-tz- extension' => sub
{
    my $dt = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
    ok( defined( $dt ), 'now() succeeds with BCP47 tz locale' );
    is( $dt->time_zone_long_name, 'Asia/Jerusalem',
        'now() timezone inferred as Asia/Jerusalem from -u-tz-jeruslm' );
};

# NOTE: Arabic locale with Latin numerals - no tz extension, falls back to default
subtest 'Locale without -u-tz- uses default timezone' => sub
{
    my $dt = DateTime::Lite->new(
        year   => 2026,
        month  => 4,
        day    => 10,
        locale => 'ar-SA-u-nu-latn',
    );
    ok( defined( $dt ), 'new() succeeds with locale without -u-tz- extension' );
    # Default timezone is 'floating' unless PERL_DATETIME_DEFAULT_TZ is set
    my $expected = $ENV{PERL_DATETIME_DEFAULT_TZ} || 'floating';
    is( $dt->time_zone_long_name, $expected,
        "no -u-tz- extension: falls back to default timezone ($expected)" );
};

# NOTE: another -u-tz- zone: Tokyo
subtest 'BCP47 -u-tz- for Tokyo' => sub
{
    my $dt = DateTime::Lite->new(
        year   => 2026,
        month  => 4,
        day    => 10,
        locale => 'ja-JP-u-tz-jptyo',
    );
    ok( defined( $dt ), 'new() succeeds with -u-tz-jptyo' );
    is( $dt->time_zone_long_name, 'Asia/Tokyo',
        'timezone inferred as Asia/Tokyo from -u-tz-jptyo' );
};

# NOTE: New York via -u-tz-
subtest 'BCP47 -u-tz- for New York' => sub
{
    my $dt = DateTime::Lite->new(
        year   => 2026,
        month  => 4,
        day    => 10,
        locale => 'en-US-u-tz-usnyc',
    );
    ok( defined( $dt ), 'new() succeeds with -u-tz-usnyc' );
    is( $dt->time_zone_long_name, 'America/New_York',
        'timezone inferred as America/New_York from -u-tz-usnyc' );
};

# NOTE: _set_locale robustness: blessed object passed directly
subtest '_set_locale accepts blessed locale object' => sub
{
    require DateTime::Locale::FromCLDR;
    my $locale_obj = DateTime::Locale::FromCLDR->new( 'fr-FR' );
    ok( defined( $locale_obj ), 'DateTime::Locale::FromCLDR object created' );

    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 10,
        time_zone => 'UTC',
        locale    => $locale_obj,
    );
    ok( defined( $dt ),         'new() accepts blessed locale object' );
    is( $dt->locale->language_code, 'fr', 'locale correctly set to fr-FR' );
};

# NOTE: _set_locale robustness: unblessed reference returns error, not die
subtest '_set_locale rejects unblessed reference gracefully' => sub
{
    local $SIG{__WARN__} = sub {};
    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 10,
        time_zone => 'UTC',
        locale    => {},    # unblessed hashref - should error, not die
    );
    ok( !defined( $dt ), 'new() returns undef for unblessed ref locale' );
    ok( defined( DateTime::Lite->error ), 'error object is set' );
};

# NOTE: from_epoch with BCP47 -u-tz- locale
subtest 'from_epoch() infers timezone from -u-tz- extension' => sub
{
    my $dt = DateTime::Lite->from_epoch(
        epoch  => 1775769030,
        locale => 'he-IL-u-ca-hebrew-tz-jeruslm',
    );
    ok( defined( $dt ), 'from_epoch() succeeds with BCP47 tz locale' );
    is( $dt->time_zone_long_name, 'Asia/Jerusalem',
        'from_epoch() timezone inferred as Asia/Jerusalem from -u-tz-jeruslm' );
};

# NOTE: from_epoch explicit time_zone takes priority over -u-tz-
subtest 'from_epoch() explicit time_zone takes priority over -u-tz-' => sub
{
    my $dt = DateTime::Lite->from_epoch(
        epoch     => 1775769030,
        time_zone => 'Asia/Tokyo',
        locale    => 'he-IL-u-ca-hebrew-tz-jeruslm',
    );
    ok( defined( $dt ), 'from_epoch() succeeds with both time_zone and BCP47 locale' );
    is( $dt->time_zone_long_name, 'Asia/Tokyo',
        'from_epoch() explicit time_zone=Asia/Tokyo takes priority over -u-tz-jeruslm' );
};

# NOTE: from_day_of_year with BCP47 -u-tz- locale
subtest 'from_day_of_year() infers timezone from -u-tz- extension' => sub
{
    my $dt = DateTime::Lite->from_day_of_year(
        year        => 2026,
        day_of_year => 100,
        locale      => 'ja-JP-u-tz-jptyo',
    );
    ok( defined( $dt ), 'from_day_of_year() succeeds with BCP47 tz locale' );
    is( $dt->time_zone_long_name, 'Asia/Tokyo',
        'from_day_of_year() timezone inferred as Asia/Tokyo from -u-tz-jptyo' );
};

# NOTE: last_day_of_month with BCP47 -u-tz- locale
subtest 'last_day_of_month() infers timezone from -u-tz- extension' => sub
{
    my $dt = DateTime::Lite->last_day_of_month(
        year   => 2026,
        month  => 4,
        locale => 'en-US-u-tz-usnyc',
    );
    ok( defined( $dt ), 'last_day_of_month() succeeds with BCP47 tz locale' );
    is( $dt->time_zone_long_name, 'America/New_York',
        'last_day_of_month() timezone inferred as America/New_York from -u-tz-usnyc' );
    is( $dt->day, 30, 'last_day_of_month() correct day (April has 30 days)' );
};

# NOTE: from_object with BCP47 -u-tz- locale
subtest 'from_object() infers timezone from -u-tz- extension' => sub
{
    # Source object in UTC
    my $source = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 10,
        hour      => 12,
        time_zone => 'UTC',
    );
    ok( defined( $source ), 'source object created' );

    my $dt = DateTime::Lite->from_object(
        object => $source,
        locale => 'ja-JP-u-tz-jptyo',
    );
    ok( defined( $dt ), 'from_object() succeeds with BCP47 tz locale' );
    is( $dt->time_zone_long_name, 'Asia/Tokyo',
        'from_object() timezone inferred as Asia/Tokyo from -u-tz-jptyo' );
    # Tokyo is UTC+9, so 12:00 UTC = 21:00 JST
    is( $dt->hour, 21, 'from_object() hour correctly shifted to JST' );
};

# NOTE: from_object explicit time_zone takes priority over -u-tz-
subtest 'from_object() explicit time_zone takes priority over -u-tz-' => sub
{
    my $source = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 10,
        hour      => 12,
        time_zone => 'UTC',
    );
    my $dt = DateTime::Lite->from_object(
        object    => $source,
        time_zone => 'Europe/Paris',
        locale    => 'ja-JP-u-tz-jptyo',
    );
    ok( defined( $dt ), 'from_object() succeeds with both time_zone and BCP47 locale' );
    is( $dt->time_zone_long_name, 'Europe/Paris',
        'from_object() explicit time_zone=Europe/Paris takes priority over -u-tz-jptyo' );
};

# NOTE: Locale::Unicode object passed directly (case 2 of _resolve_time_zone)
subtest 'Locale::Unicode object passed directly carries -u-tz- intact' => sub
{
    require Locale::Unicode;
    my $loc = Locale::Unicode->new( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    ok( defined( $loc ), 'Locale::Unicode object created' );
    ok( defined( $loc->tz ), 'Locale::Unicode->tz is defined' );
    is( $loc->tz, 'jeruslm', 'Locale::Unicode->tz returns jeruslm' );

    my $dt = DateTime::Lite->new(
        year   => 2026,
        month  => 4,
        day    => 10,
        locale => $loc,
    );
    ok( defined( $dt ), 'new() succeeds with Locale::Unicode object' );
    is( $dt->time_zone_long_name, 'Asia/Jerusalem',
        'timezone inferred from Locale::Unicode object carrying -u-tz-jeruslm' );
};

# NOTE: set_locale() on a floating object infers timezone from -u-tz-
subtest 'set_locale() infers timezone on floating object' => sub
{
    my $dt = DateTime::Lite->new(
        year  => 2026,
        month => 4,
        day   => 10,
        hour  => 12,
    );
    ok( defined( $dt ), 'object created with floating timezone' );
    is( $dt->time_zone_long_name, 'floating', 'initially floating' );

    $dt->set_locale( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    is( $dt->time_zone_long_name, 'Asia/Jerusalem',
        'set_locale() inferred Asia/Jerusalem from -u-tz-jeruslm on floating object' );
};

# NOTE: set_locale() does NOT change timezone if object already has one
subtest 'set_locale() does not change timezone on non-floating object' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 10,
        hour      => 12,
        time_zone => 'Asia/Tokyo',
    );
    ok( defined( $dt ), 'object created with explicit timezone' );
    is( $dt->time_zone_long_name, 'Asia/Tokyo', 'initially Asia/Tokyo' );

    $dt->set_locale( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    is( $dt->time_zone_long_name, 'Asia/Tokyo',
        'set_locale() did not change timezone on non-floating object' );
};

done_testing;

__END__

