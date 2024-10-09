#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG $TEST_ID );
    use utf8;
    use version;
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $TEST_ID = $ENV{TEST_ID} if( exists( $ENV{TEST_ID} ) );
    # Browser unit tests starts at offset 6
};

BEGIN
{
    use_ok( 'DateTime::Format::Intl' ) || BAIL_OUT( 'Unable to load DateTime::Format::Intl' );
};

use strict;
use warnings;
use utf8;


my $tests = 
[
    # NOTE: en -> {}
    {
        locale => 'en',
        options => {},
        expects => 
            {
                year => 'numeric',
                month => 'numeric',
                day => 'numeric',
            },
    },
    # NOTE: fr -> {timeStyle}
    {
        locale => 'fr',
        options =>
            {
                timeStyle => 'long',
                timeZone => 'Europe/Paris',
            },
        expects => 
            {
                calendar => 'gregorian',
                hour12 => 0,
                hourCycle => 'h23',
                locale => 'fr',
                numberingSystem => 'latn',
                timeStyle => 'long',
                timeZone => 'Europe/Paris',
            },
    },
    # NOTE: ja-JP -> {dateStyle, timeZone}
    {
        locale => 'ja-JP',
        options =>
            {
                dateStyle => 'long',
                timeZone => 'Asia/Tokyo',
            },
        expects => 
            {
                calendar => 'gregorian',
                dateStyle => 'long',
                locale => 'ja-JP',
                numberingSystem => 'latn',
                timeZone => 'Asia/Tokyo',
            },
    },
    # NOTE: fr-CH,de-CH  -> {hour,minute,second, weekday,timeZone}
    {
        locale => ['fr-CH', 'de-CH'],
        options =>
            {
                hour => 'numeric',
                minute => 'numeric',
                second => 'numeric',
                weekday => 'long',
                timeZone => 'Europe/Zurich',
            },
        expects => 
            {
                calendar => 'gregorian',
                hour => '2-digit',
                minute => '2-digit',
                second => '2-digit',
                locale => 'fr-CH',
                hour12 => 0,
                hourCycle => 'h23',
                weekday => 'long',
                numberingSystem => 'latn',
                timeZone => 'Europe/Zurich',
            },
    },
    # NOTE: ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo -> {timeZone}
    {
        # locale => 'ja-Kana-JP-u-ca-japanese-nu-jpanfin-tz-jptyo',
        locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
        options => 
            {
                timeZone => 'Europe/Zurich',
            },
        expects => 
            {
                calendar => 'gregorian',
                year => 'numeric',
                month => 'numeric',
                day => 'numeric',
                locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
                numberingSystem => 'jpanfin',
                # The time zone passed as option takes precedence over the locale 'ca' extension
                timeZone => 'Europe/Zurich',
            },
    },
    # NOTE: ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo -> {}
    {
        # locale => 'ja-Kana-JP-u-ca-japanese-nu-jpanfin-tz-jptyo',
        locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
        options => {},
        expects => 
            {
                calendar => 'gregorian',
                year => 'numeric',
                month => 'numeric',
                day => 'numeric',
                locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
                numberingSystem => 'jpanfin',
                # The time zone passed as option takes precedence over the locale 'ca' extension
                timeZone => 'Asia/Tokyo',
            },
    },
    # Checking all 47 possibilities
    # NOTE: en -> {dayPeriod, hour
    {
        expects => {
            calendar => "gregorian",
            dayPeriod => "short",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {dayPeriod, hour, minute}
    {
        expects => {
            calendar => "gregorian",
            dayPeriod => "short",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric", minute => "numeric", timeZone => "UTC" },
    },
    # z
    {
        expects => {
            calendar => "gregorian",
            dayPeriod => "short",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
        },
        locale => "en",
        options => {
            dayPeriod => "short",
            hour => "numeric",
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {weekday}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => { weekday => "short", timeZone => "UTC" },
    },
    # NOTE: en -> {dayPeriod, hour, minute, weekday}
    {
        expects => {
            calendar => "gregorian",
            dayPeriod => "short",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => {
            dayPeriod => "short",
            hour => "numeric",
            minute => "numeric",
            weekday => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {dayPeriod, hour, minute, second, weekday}
    {
        expects => {
            calendar => "gregorian",
            dayPeriod => "short",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => {
            dayPeriod => "short",
            hour => "numeric",
            minute => "numeric",
            second => "numeric",
            weekday => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {hour, hour12, minute, weekday}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            weekday => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {hour, hour12, minute, second, weekday}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            weekday => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {day, weekday}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => { day => "numeric", weekday => "short", timeZone => "UTC" },
    },
    # NOTE: en -> {era, year}
    {
        expects => {
            calendar => "gregorian",
            era => "short",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { era => "short", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {era, month, year}
    {
        expects => {
            calendar => "gregorian",
            era => "short",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { era => "short", month => "short", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, era, month, weekday, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            era => "short",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
            year => "numeric",
        },
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "short",
            weekday => "short",
            year => "numeric",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {day, era, month, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            era => "short",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { day => "numeric", era => "short", month => "short", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, era, month, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            era => "short",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "numeric",
            year => "numeric",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {hour, hour12}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { hour => "numeric", hour12 => 1, timeZone => "UTC" },
    },
    # NOTE: en -> {hour, hour12, minute}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { hour => "numeric", hour12 => 1, minute => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {hour, hour12, minute, second}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {hour, hour12, minute, second, timeZoneName}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            timeZoneName => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {hour, hour12, minute, timeZoneName}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            timeZoneName => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {day, month}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { day => "numeric", month => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {month}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { month => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, weekday}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => { day => "numeric", month => "numeric", weekday => "short", timeZone => "UTC" },
    },
    # NOTE: en -> {month}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { month => "short", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, weekday}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
        },
        locale => "en",
        options => { day => "numeric", month => "short", weekday => "short", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "long",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { day => "numeric", month => "long", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "long",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { day => "numeric", month => "long", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { day => "numeric", month => "short", timeZone => "UTC" },
    },
    # NOTE: en -> {day}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { day => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {hour, hour12}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { hour => "numeric", hour12 => 1, timeZone => "UTC" },
    },
    # NOTE: en -> {hour, hour12, minute}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            timeZone => "UTC",
        },
        locale => "en",
        options => { hour => "numeric", hour12 => 1, minute => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {hour, hour12, minute, second}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {hour, hour12, minute, second, timeZoneName}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            timeZoneName => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {hour, hour12, minute, timeZoneName}
    {
        expects => {
            calendar => "gregorian",
            hour => "numeric",
            hour12 => 1,
            hourCycle => "h12",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            timeZoneName => "short",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {minute, second}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            minute => "2-digit",
            numberingSystem => "latn",
            second => "2-digit",
            timeZone => "UTC",
        },
        locale => "en",
        options => { minute => "numeric", second => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {year}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {month, year}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { month => "numeric", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, weekday, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
            year => "numeric",
        },
        locale => "en",
        options => {
            day => "numeric",
            month => "numeric",
            weekday => "short",
            year => "numeric",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {month, year}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { month => "short", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, weekday, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
            weekday => "short",
            year => "numeric",
        },
        locale => "en",
        options => {
            day => "numeric",
            month => "short",
            weekday => "short",
            year => "numeric",
            timeZone => "UTC",
        },
    },
    # NOTE: en -> {month, year}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            month => "long",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { month => "long", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "short",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { day => "numeric", month => "short", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { day => "numeric", month => "numeric", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {month, year}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { month => "numeric", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {month, year}
    {
        expects => {
            calendar => "gregorian",
            locale => "en",
            month => "long",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { month => "long", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {day, month, year}
    {
        expects => {
            calendar => "gregorian",
            day => "numeric",
            locale => "en",
            month => "numeric",
            numberingSystem => "latn",
            timeZone => "UTC",
            year => "numeric",
        },
        locale => "en",
        options => { day => "numeric", month => "numeric", year => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {minute}
    # A singleton, not part of the available pattern
    {
        expects => {
            calendar => "gregorian",
            minute => "2-digit",
            locale => "en",
            timeZone => "UTC",
        },
        locale => "en",
        options => { minute => "numeric", timeZone => "UTC" },
    },
    # NOTE: en -> {second}
    # A singleton, not part of the available pattern
    {
        expects => {
            calendar => "gregorian",
            second => "2-digit",
            locale => "en",
            timeZone => "UTC",
        },
        locale => "en",
        options => { second => "numeric", timeZone => "UTC" },
    },
];

my $failed = [];
for( my $i = 0; $i < scalar( @$tests ); $i++ )
{
    if( defined( $TEST_ID ) )
    {
        next unless( $i == $TEST_ID );
        last if( $i > $TEST_ID );
    }
    my $test = $tests->[$i];
    my @keys = sort( keys( %{$test->{options}} ) );
    local $" = ', ';
    subtest 'DateTime::Format::Intl->new( ' . ( ref( $test->{locale} ) eq 'ARRAY' ? "[@{$test->{locale}}]" : $test->{locale} ) . ", \{@keys\} )" => sub
    {
        local $SIG{__DIE__} = sub
        {
            diag( "Test No ${i} died: ", join( '', @_ ) );
        };
        my $fmt = DateTime::Format::Intl->new( $test->{locale}, $test->{options} );
        diag( "Error instantiating a new DateTime::Format::Intl object: ", DateTime::Format::Intl->error ) if( !defined( $fmt ) );
        isa_ok( $fmt => 'DateTime::Format::Intl' );
        next if( !defined( $fmt ) );
        my $opts = $fmt->resolvedOptions;
        my $has_failed = 0;
        foreach my $k ( sort( keys( %{$test->{expects}} ) ) )
        {
            if( !exists( $opts->{ $k } ) )
            {
                fail( "Missing expected option \"${k}\" in resolvedOptions hash." );
                $has_failed++;
                push( @$failed, { test => $i, %$test } );
            }
            elsif( ( !defined( $opts->{ $k } ) && defined( $test->{expects}->{ $k } ) ) ||
                     $opts->{ $k } ne $test->{expects}->{ $k } )
            {
                fail( "Option \"${k}\" value expected was \"" . ( $test->{expects}->{ $k } // 'undef' ) . "\", but got \"" . ( $opts->{ $k } // 'undef' ) . "\"." );
                $has_failed++;
                push( @$failed, { test => $i, %$test } );
            }
        }
        pass( "resolvedOptions hash received matches: @keys" ) unless( $has_failed );
    };
}

done_testing();

__END__
