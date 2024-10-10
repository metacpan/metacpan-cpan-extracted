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
    use DateTime;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $TEST_ID = $ENV{TEST_ID} if( exists( $ENV{TEST_ID} ) );
};

BEGIN
{
    use_ok( 'DateTime::Format::Intl' ) || BAIL_OUT( 'Unable to load DateTime::Format::Intl' );
};

use strict;
use warnings;
use utf8;

my $dt = DateTime->new(
    year => 2024,
    month => 9,
    day => 24,
    hour => 9,
    minute => 0,
    second => 10,
    time_zone => 'UTC',
);
my $date = $dt->iso8601;

my $tests =
[
    {
        expects => "9/24/2024",
        expects_parts => [
            { type => "month", value => 9 },
            { type => "literal", value => "/" },
            { type => "day", value => 24 },
            { type => "literal", value => "/" },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => {},
    },
    {
        expects => "9 in the morning",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "in the morning" },
        ],
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric", timeZone => "UTC" },
        skeleton => "Bh",
    },
    {
        expects => "9:00 in the morning",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "in the morning" },
        ],
        locale => "en",
        options => {
            dayPeriod => "short",
            hour => "numeric",
            minute => "numeric",
            timeZone => "UTC",
        },
        skeleton => "Bhm",
    },
    {
        expects => "9:00:10 in the morning",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "in the morning" },
        ],
        locale => "en",
        options => {
            dayPeriod => "short",
            hour => "numeric",
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
        },
        skeleton => "Bhms",
    },
    {
        expects => "Tue",
        expects_parts => [{ type => "weekday", value => "Tue" }],
        locale => "en",
        options => { timeZone => "UTC", weekday => "short" },
        skeleton => "E",
    },
    {
        expects => "Tue 9:00 in the morning",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => " " },
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "in the morning" },
        ],
        locale => "en",
        options => {
            dayPeriod => "short",
            hour => "numeric",
            minute => "numeric",
            timeZone => "UTC",
            weekday => "short",
        },
        skeleton => "EBhm",
    },
    {
        expects => "Tue 9:00:10 in the morning",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => " " },
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "in the morning" },
        ],
        locale => "en",
        options => {
            dayPeriod => "short",
            hour => "numeric",
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
            weekday => "short",
        },
        skeleton => "EBhms",
    },
    {
        expects => "Tue 09:00",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => " " },
            { type => "hour", value => "09" },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 0,
            minute => "numeric",
            timeZone => "UTC",
            weekday => "short",
        },
        skeleton => "EHm",
    },
    {
        expects => "Tue 09:00:10",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => " " },
            { type => "hour", value => "09" },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 0,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
            weekday => "short",
        },
        skeleton => "EHms",
    },
    {
        expects => "Tue 9:00 AM",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => " " },
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "AM" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            timeZone => "UTC",
            weekday => "short",
        },
        skeleton => "Ehm",
    },
    {
        expects => "Tue 9:00:10 AM",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => " " },
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "AM" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
            weekday => "short",
        },
        skeleton => "Ehms",
    },
    {
        expects => "24 Tue",
        expects_parts => [
            { type => "day", value => 24 },
            { type => "literal", value => " " },
            { type => "weekday", value => "Tue" },
        ],
        locale => "en",
        options => { day => "numeric", timeZone => "UTC", weekday => "short" },
        skeleton => "Ed",
    },
    {
        expects => "2024 AD",
        expects_parts => [
            { type => "year", value => 2024 },
            { type => "literal", value => " " },
            { type => "era", value => "AD" },
        ],
        locale => "en",
        options => { era => "short", timeZone => "UTC", year => "numeric" },
        skeleton => "Gy",
    },
    {
        expects => "Sep 2024 AD",
        expects_parts => [
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "year", value => 2024 },
            { type => "literal", value => " " },
            { type => "era", value => "AD" },
        ],
        locale => "en",
        options => { era => "short", month => "short", timeZone => "UTC", year => "numeric" },
        skeleton => "GyMMM",
    },
    {
        expects => "Tue, Sep 24, 2024 AD",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "day", value => 24 },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "year", value => 2024 },
            { type => "literal", value => " " },
            { type => "era", value => "AD" },
        ],
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "short",
            timeZone => "UTC",
            weekday => "short",
            year => "numeric",
        },
        skeleton => "GyMMMEd",
    },
    {
        expects => "Sep 24, 2024 AD",
        expects_parts => [
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "day", value => 24 },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "year", value => 2024 },
            { type => "literal", value => " " },
            { type => "era", value => "AD" },
        ],
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "short",
            timeZone => "UTC",
            year => "numeric",
        },
        skeleton => "GyMMMd",
    },
    {
        expects => "9/24/2024 AD",
        expects_parts => [
            { type => "month", value => 9 },
            { type => "literal", value => "/" },
            { type => "day", value => 24 },
            { type => "literal", value => "/" },
            { type => "year", value => 2024 },
            { type => "literal", value => " " },
            { type => "era", value => "AD" },
        ],
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "numeric",
            timeZone => "UTC",
            year => "numeric",
        },
        skeleton => "GyMd",
    },
    {
        expects => "09",
        expects_parts => [{ type => "hour", value => "09" }],
        locale => "en",
        options => { hour => "numeric", hour12 => 0, timeZone => "UTC" },
        skeleton => "H",
    },
    {
        expects => "09:00",
        expects_parts => [
            { type => "hour", value => "09" },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
        ],
        locale => "en",
        options => { hour => "numeric", hour12 => 0, minute => "numeric", timeZone => "UTC" },
        skeleton => "Hm",
    },
    {
        expects => "09:00:10",
        expects_parts => [
            { type => "hour", value => "09" },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 0,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
        },
        skeleton => "Hms",
    },
    {
        expects => "09:00:10 UTC",
        expects_parts => [
            { type => "hour", value => "09" },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
            { type => "literal", value => " " },
            { type => "timeZoneName", value => "UTC" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 0,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        skeleton => "Hmsv",
    },
    {
        expects => "09:00 UTC",
        expects_parts => [
            { type => "hour", value => "09" },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => " " },
            { type => "timeZoneName", value => "UTC" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 0,
            minute => "numeric",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        skeleton => "Hmv",
    },
    {
        expects => "9/24",
        expects_parts => [
            { type => "month", value => 9 },
            { type => "literal", value => "/" },
            { type => "day", value => 24 },
        ],
        locale => "en",
        options => { day => "numeric", month => "numeric", timeZone => "UTC" },
        skeleton => "Md",
    },
    {
        expects => 9,
        expects_parts => [{ type => "month", value => 9 }],
        locale => "en",
        options => { month => "numeric", timeZone => "UTC" },
        skeleton => "M",
    },
    {
        expects => "Tue, 9/24",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "month", value => 9 },
            { type => "literal", value => "/" },
            { type => "day", value => 24 },
        ],
        locale => "en",
        options => { day => "numeric", month => "numeric", timeZone => "UTC", weekday => "short" },
        skeleton => "MEd",
    },
    {
        expects => "Sep",
        expects_parts => [{ type => "month", value => "Sep" }],
        locale => "en",
        options => { month => "short", timeZone => "UTC" },
        skeleton => "MMM",
    },
    {
        expects => "September",
        expects_parts => [{ type => "month", value => "September" }],
        locale => "en",
        options => { month => "long", timeZone => "UTC" },
        skeleton => "MMMM",
    },
    {
        expects => "S",
        expects_parts => [{ type => "month", value => "S" }],
        locale => "en",
        options => { month => "narrow", timeZone => "UTC" },
        skeleton => "MMMMM",
    },
    {
        expects => "Tue, Sep 24",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "day", value => 24 },
        ],
        locale => "en",
        options => { day => "numeric", month => "short", timeZone => "UTC", weekday => "short" },
        skeleton => "MMMEd",
    },
    {
        expects => "September 24",
        expects_parts => [
            { type => "month", value => "September" },
            { type => "literal", value => " " },
            { type => "day", value => 24 },
        ],
        locale => "en",
        options => { day => "numeric", month => "long", timeZone => "UTC" },
        skeleton => "MMMMd",
    },
    {
        expects => "Sep 24",
        expects_parts => [
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "day", value => 24 },
        ],
        locale => "en",
        options => { day => "numeric", month => "short", timeZone => "UTC" },
        skeleton => "MMMd",
    },
    {
        expects => 24,
        expects_parts => [{ type => "day", value => 24 }],
        locale => "en",
        options => { day => "numeric", timeZone => "UTC" },
        skeleton => "d",
    },
    {
        expects => "9 AM",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "AM" },
        ],
        locale => "en",
        options => { hour => "numeric", hour12 => 1, timeZone => "UTC" },
        skeleton => "h",
    },
    {
        expects => "9:00 AM",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "AM" },
        ],
        locale => "en",
        options => { hour => "numeric", hour12 => 1, minute => "numeric", timeZone => "UTC" },
        skeleton => "hm",
    },
    {
        expects => "9:00:10 AM",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "AM" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
        },
        skeleton => "hms",
    },
    {
        expects => "9:00:10 AM UTC",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "AM" },
            { type => "literal", value => " " },
            { type => "timeZoneName", value => "UTC" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            second => "numeric",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        skeleton => "hmsv",
    },
    {
        expects => "9:00 AM UTC",
        expects_parts => [
            { type => "hour", value => 9 },
            { type => "literal", value => ":" },
            { type => "minute", value => "00" },
            { type => "literal", value => " " },
            { type => "dayPeriod", value => "AM" },
            { type => "literal", value => " " },
            { type => "timeZoneName", value => "UTC" },
        ],
        locale => "en",
        options => {
            hour => "numeric",
            hour12 => 1,
            minute => "numeric",
            timeZone => "UTC",
            timeZoneName => "short",
        },
        skeleton => "hmv",
    },
    {
        expects => "00:10",
        expects_parts => [
            { type => "minute", value => "00" },
            { type => "literal", value => ":" },
            { type => "second", value => 10 },
        ],
        locale => "en",
        options => { minute => "numeric", second => "numeric", timeZone => "UTC" },
        skeleton => "ms",
    },
    {
        expects => 2024,
        expects_parts => [{ type => "year", value => 2024 }],
        locale => "en",
        options => { timeZone => "UTC", year => "numeric" },
        skeleton => "y",
    },
    {
        expects => "9/2024",
        expects_parts => [
            { type => "month", value => 9 },
            { type => "literal", value => "/" },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => { month => "numeric", timeZone => "UTC", year => "numeric" },
        skeleton => "yM",
    },
    {
        expects => "Tue, 9/24/2024",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "month", value => 9 },
            { type => "literal", value => "/" },
            { type => "day", value => 24 },
            { type => "literal", value => "/" },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => {
            day => "numeric",
            month => "numeric",
            timeZone => "UTC",
            weekday => "short",
            year => "numeric",
        },
        skeleton => "yMEd",
    },
    {
        expects => "Sep 2024",
        expects_parts => [
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => { month => "short", timeZone => "UTC", year => "numeric" },
        skeleton => "yMMM",
    },
    {
        expects => "Tue, Sep 24, 2024",
        expects_parts => [
            { type => "weekday", value => "Tue" },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "day", value => 24 },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => {
            day => "numeric",
            month => "short",
            timeZone => "UTC",
            weekday => "short",
            year => "numeric",
        },
        skeleton => "yMMMEd",
    },
    {
        expects => "September 2024",
        expects_parts => [
            { type => "month", value => "September" },
            { type => "literal", value => " " },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => { month => "long", timeZone => "UTC", year => "numeric" },
        skeleton => "yMMMM",
    },
    {
        expects => "Sep 24, 2024",
        expects_parts => [
            { type => "month", value => "Sep" },
            { type => "literal", value => " " },
            { type => "day", value => 24 },
            { type => "literal", value => "," },
            { type => "literal", value => " " },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => { day => "numeric", month => "short", timeZone => "UTC", year => "numeric" },
        skeleton => "yMMMd",
    },
    {
        expects => "9/24/2024",
        expects_parts => [
            { type => "month", value => 9 },
            { type => "literal", value => "/" },
            { type => "day", value => 24 },
            { type => "literal", value => "/" },
            { type => "year", value => 2024 },
        ],
        locale => "en",
        options => { day => "numeric", month => "numeric", timeZone => "UTC", year => "numeric" },
        skeleton => "yMd",
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
    subtest 'DateTime::Format::Intl->new( ' . ( ref( $test->{locale} ) eq 'ARRAY' ? "[@{$test->{locale}}]" : $test->{locale} ) . ", \{@keys\} )->format_to_parts( ${date} )" => sub
    {
        local $SIG{__DIE__} = sub
        {
            diag( "Test No ${i} died: ", join( '', @_ ) );
        };
        my $fmt = DateTime::Format::Intl->new( $test->{locale}, $test->{options} );
        SKIP:
        {
            isa_ok( $fmt => 'DateTime::Format::Intl' );
            if( !defined( $fmt ) )
            {
                diag( "Error instantiating the DateTime::Format::Intl object: ", DateTime::Format::Intl->error );
                skip( "Unable to instantiate a new DateTime::Format::Intl object.", 1 );
            }
            my $ref = $fmt->format_to_parts( $dt );
            if( !defined( $ref ) )
            {
                diag( "Error formatting date ${date} to parts: ", $fmt->error );
                fail( "Error formatting date ${date} to parts: " . $fmt->error );
                next;
            }
            if( !is_deeply( $ref => $test->{expects_parts}, "\$fmt->format_to_parts( $date ) -> '" . join( ', ', @{$test->{expects_parts}} ) . "'" ) )
            {
                push( @$failed, { test => $i, parts => $ref, %$test } );
            }
        };
    };
}


done_testing();

__END__
