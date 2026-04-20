# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/10.basic.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use utf8;
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );

# NOTE: Helper: build a formatter, parse, check fields, optionally round-trip.
sub check_parse
{
    my( %args ) = @_;
    my $label          = $args{name};
    my $pattern        = $args{pattern};
    my $input          = $args{input};
    my $expect         = $args{expect};
    my $skip_roundtrip = $args{skip_roundtrip} // 0;
    my $locale         = $args{locale};

    subtest $label => sub
    {
        my %new_args = ( pattern => $pattern, on_error => 'undef' );
        $new_args{locale} = $locale if( defined( $locale ) );

        my $fmt = DateTime::Format::Lite->new( %new_args );
        ok( defined( $fmt ), "constructor succeeded for pattern $pattern" ) or return;

        my $dt = $fmt->parse_datetime( $input );
        if( ok( defined( $dt ), "parsed '$input'" ) )
        {
            foreach my $meth ( sort( keys( %$expect ) ) )
            {
                is( $dt->$meth, $expect->{ $meth }, "$meth is $expect->{ $meth }" );
            }

            unless( $skip_roundtrip )
            {
                is( $fmt->format_datetime( $dt ), $input, 'round-trip via format_datetime' );
            }
        }
        else
        {
            diag( "Error: " . ( $fmt->error // 'unknown' ) );
        }
    };
}

# Date tokens
# NOTE: ISO8601 datetime
check_parse(
    name    => 'ISO8601 datetime',
    pattern => '%Y-%m-%dT%H:%M:%S',
    input   => '2026-04-15T09:30:00',
    expect  => { year => 2026, month => 4, day => 15, hour => 9, minute => 30, second => 0 },
);

# NOTE: 4-digit year
check_parse(
    name    => '4-digit year',
    pattern => '%Y-%m-%d',
    input   => '1998-12-31',
    expect  => { year => 1998, month => 12, day => 31 },
);

# NOTE: 2-digit year
check_parse(
    name    => '2-digit year',
    pattern => '%y-%m-%d',
    input   => '98-12-31',
    expect  => { year => 1998, month => 12, day => 31 },
    skip_roundtrip => 1,
);

# NOTE: day-of-year %j
check_parse(
    name    => 'day-of-year %j',
    pattern => '%Y years %j days',
    input   => '1998 years 312 days',
    expect  => { year => 1998, month => 11, day => 8 },
    skip_roundtrip => 1,
);

# NOTE: abbreviated month %b
check_parse(
    name    => 'abbreviated month %b',
    pattern => '%b %d %Y',
    input   => 'Jan 24 2003',
    expect  => { year => 2003, month => 1, day => 24 },
);

# NOTE: abbreviated month case-insensitive
check_parse(
    name    => 'abbreviated month case-insensitive',
    pattern => '%b %d %Y',
    input   => 'jAN 24 2003',
    expect  => { year => 2003, month => 1, day => 24 },
    skip_roundtrip => 1,
);

# NOTE: full month %B
check_parse(
    name    => 'full month %B',
    pattern => '%B %d %Y',
    input   => 'January 24 2003',
    expect  => { year => 2003, month => 1, day => 24 },
);

# NOTE: full month case-insensitive
check_parse(
    name    => 'full month case-insensitive',
    pattern => '%B %d %Y',
    input   => 'jAnUAry 24 2003',
    expect  => { year => 2003, month => 1, day => 24 },
    skip_roundtrip => 1,
);

# NOTE: leading-space day %e
check_parse(
    name    => 'leading-space day %e',
    pattern => '%e-%b-%Y',
    input   => ' 3-Jun-2010',
    expect  => { year => 2010, month => 6, day => 3 },
    skip_roundtrip => 1,
);

# NOTE: Time tokens
# NOTE: 24-hour time %H:%M:%S
check_parse(
    name    => '24-hour time %H:%M:%S',
    pattern => '%H:%M:%S',
    input   => '23:45:56',
    expect  => { hour => 23, minute => 45, second => 56 },
);

# NOTE: 12-hour time PM %l:%M:%S %p
check_parse(
    name    => '12-hour time PM %l:%M:%S %p',
    pattern => '%l:%M:%S %p',
    input   => '11:45:56 PM',
    expect  => { hour => 23, minute => 45, second => 56 },
);

# NOTE: 12-hour time am case-insensitive
check_parse(
    name    => '12-hour time am case-insensitive',
    pattern => '%l:%M:%S %p',
    input   => '11:45:56 am',
    expect  => { hour => 11, minute => 45, second => 56 },
    skip_roundtrip => 1,
);

# NOTE: compound %T
check_parse(
    name    => 'compound %T',
    pattern => '%T',
    input   => '23:34:45',
    expect  => { hour => 23, minute => 34, second => 45 },
);

# NOTE: compound %r (12-hour with AM/PM)
check_parse(
    name    => 'compound %r (12-hour with AM/PM)',
    pattern => '%r',
    input   => '11:34:45 PM',
    expect  => { hour => 23, minute => 34, second => 45 },
);

# NOTE: compound %R (HH:MM)
check_parse(
    name    => 'compound %R (HH:MM)',
    pattern => '%R',
    input   => '23:34',
    expect  => { hour => 23, minute => 34, second => 0 },
    skip_roundtrip => 1,
);

# NOTE: Nanoseconds
# NOTE: nanosecond %N (9 digits)
check_parse(
    name    => 'nanosecond %N (9 digits)',
    pattern => '%H:%M:%S.%N',
    input   => '23:45:56.123456789',
    expect  => { hour => 23, minute => 45, second => 56, nanosecond => 123456789 },
);

# NOTE: nanosecond %6N
check_parse(
    name           => 'nanosecond %6N',
    pattern        => '%H:%M:%S.%6N',
    input          => '23:45:56.123456',
    expect         => { hour => 23, minute => 45, second => 56, nanosecond => 123456000 },
    skip_roundtrip => 1,
);

# NOTE: nanosecond %3N
check_parse(
    name           => 'nanosecond %3N',
    pattern        => '%H:%M:%S.%3N',
    input          => '23:45:56.123',
    expect         => { hour => 23, minute => 45, second => 56, nanosecond => 123000000 },
    skip_roundtrip => 1,
);

# NOTE: Compound date tokens
# NOTE: US date %D
check_parse(
    name    => 'US date %D',
    pattern => '%D',
    input   => '11/30/03',
    expect  => { year => 2003, month => 11, day => 30 },
);

# NOTE: ISO date %F
check_parse(
    name    => 'ISO date %F',
    pattern => '%F',
    input   => '2003-11-30',
    expect  => { year => 2003, month => 11, day => 30 },
);

# Timezone tokens
# NOTE: timezone offset +HHMM
check_parse(
    name    => 'timezone offset +HHMM',
    pattern => '%H:%M:%S %z',
    input   => '23:45:56 +1030',
    expect  => { hour => 23, minute => 45, second => 56, offset => 37800 },
);

# NOTE: timezone offset -HHMM
check_parse(
    name    => 'timezone offset -HHMM',
    pattern => '%H:%M:%S %z',
    input   => '23:45:56 -1030',
    expect  => { hour => 23, minute => 45, second => 56, offset => -37800 },
);

# NOTE: timezone offset Z
check_parse(
    name    => 'timezone offset Z',
    pattern => '%H:%M:%S %z',
    input   => '23:45:56 Z',
    expect  => { hour => 23, minute => 45, second => 56, offset => 0 },
    skip_roundtrip => 1,
);

# NOTE: timezone Olson name %O
check_parse(
    name           => 'timezone Olson name %O',
    pattern        => '%H:%M:%S %O',
    input          => '23:45:56 America/Chicago',
    expect         => { hour => 23, minute => 45, second => 56, time_zone_long_name => 'America/Chicago' },
    skip_roundtrip => 1,
);

# NOTE: timezone abbreviation JST (fixed UTC+09:00, no DST)
check_parse(
    name           => 'timezone abbreviation JST',
    pattern        => '%H:%M:%S %Z',
    input          => '23:45:56 JST',
    expect         => { hour => 23, minute => 45, second => 56, offset => 32400 },
    skip_roundtrip => 1,
);

# NOTE: Epoch
# NOTE: epoch %s
check_parse(
    name    => 'epoch %s',
    pattern => '%s',
    input   => '42',
    expect  => { epoch => 42 },
    skip_roundtrip => 1,
);

# NOTE: epoch with timezone
check_parse(
    name    => 'epoch with timezone',
    pattern => '%s %Z',
    input   => '42 UTC',
    expect  => { epoch => 42, offset => 0 },
    skip_roundtrip => 1,
);

# NOTE: negative epoch (pre-1970) - value added over DateTime::Format::Strptime
# which does not support negative %s values.
check_parse(
    name           => 'negative epoch %s (pre-1970)',
    pattern        => '%s',
    input          => '-86400',
    expect         => { year => 1969, month => 12, day => 31 },
    skip_roundtrip => 1,
);

check_parse(
    name           => 'negative epoch with timezone',
    pattern        => '%s %Z',
    input          => '-86400 UTC',
    expect         => { year => 1969, month => 12, day => 31, offset => 0 },
    skip_roundtrip => 1,
);

# NOTE: Escaped percent - %% in pattern matches a single % in the input.
check_parse(
    name           => 'escaped percent %%',
    pattern        => '%Y%%%m%%%d',
    input          => '2015%05%14',
    expect         => { year => 2015, month => 5, day => 14 },
    skip_roundtrip => 1,
);

# NOTE: %Z matching a canonical zone name - short-circuit path added in v0.1.1
check_parse(
    name    => 'epoch with GMT zone name',
    pattern => '%s %Z',
    input   => '42 GMT',
    expect  => { epoch => 42, offset => 0 },
    skip_roundtrip => 1,
);

# NOTE: %Z matching an IANA zone name with a slash
check_parse(
    name           => '%Z matching full IANA zone name',
    pattern        => '%Y-%m-%d %Z',
    input          => '2026-04-19 Asia/Tokyo',
    expect         => { year => 2026, month => 4, day => 19 },
    skip_roundtrip => 1,
);

# NOTE: %Z matching an alias resolved via _resolve_alias
check_parse(
    name           => '%Z matching a zone alias (US/Eastern)',
    pattern        => '%Y-%m-%d %Z',
    input          => '2026-04-19 US/Eastern',
    expect         => { year => 2026, month => 4, day => 19 },
    skip_roundtrip => 1,
);

# NOTE: %Z matching 'Z' (Zulu) - ISO 8601 style but via %Z token
check_parse(
    name           => '%Z matching Z (Zulu)',
    pattern        => '%Y-%m-%dT%H:%M:%S %Z',
    input          => '2026-04-19T12:00:00 Z',
    expect         => { year => 2026, month => 4, day => 19, hour => 12, offset => 0 },
    skip_roundtrip => 1,
);

# NOTE: Whitespace tokens
subtest 'whitespace tokens %n and %t' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%n%Y%t%m%n', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( "\t\n  2015\n12\n" );
    if( ok( defined( $dt ), 'parsed whitespace-separated input' ) )
    {
        is( $dt->year,  2015, 'year is 2015' );
        is( $dt->month,   12, 'month is 12' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

done_testing();

__END__

