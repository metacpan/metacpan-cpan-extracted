use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;

use DateTime::Format::Strptime;

subtest(
    'valid constructor',
    sub {
        my $parser;
        is(
            exception {
                $parser = DateTime::Format::Strptime->new( pattern => '%Y' )
            },
            undef,
            'no exception when constructing object with valid pattern'
        );
        isa_ok(
            $parser,
            'DateTime::Format::Strptime',
        );
    }
);

subtest(
    'constructor error',
    sub {
        my $parser;
        like(
            exception {
                $parser
                    = DateTime::Format::Strptime->new( pattern => '%Y %Q' )
            },
            qr/\QPattern contained an unrecognized strptime token, "%Q"/,
            'no exception when constructing object with valid pattern'
        );
        is(
            $parser,
            undef,
            'constructor does not return object on invalid pattern'
        );
    }
);

{
    my @tests = (
        {
            name    => '12-hour time without meridian',
            pattern => '%Y-%m-%d %I:%M',
            input   => '2015-01-02 11:15',
            error =>
                qr{\QParsed a 12-hour based hour, "11", but the pattern does not include an AM/PM specifier},
        },
        {
            name    => 'uncrecognized time zone abbreviation',
            pattern => '%Y-%m-%d %Z',
            input   => '2015-01-02 FOO',
            error =>
                qr{\QParsed an unrecognized time zone abbreviation, "FOO"},
        },
        {
            name    => 'ambiguous time zone abbreviation',
            pattern => '%Y-%m-%d %Z',
            input   => '2015-01-02 NST',
            error =>
                qr{\QThe time zone abbreviation that was parsed is ambiguous, "NST"},
        },
        {
            name    => '24-hour vs 12-hour',
            pattern => '%Y-%m-%d %H %I %P',
            input   => '2015-01-02 13 2 AM',
            error =>
                qr{\QParsed an input with 24-hour and 12-hour time values that do not match - "13" versus "2"},
        },
        {
            name    => '24-hour vs AM/PM (13AM)',
            pattern => '%Y-%m-%d %H %P',
            input   => '2015-01-02 13 AM',
            error =>
                qr{\QParsed an input with 24-hour and AM/PM values that do not match - "13" versus "AM"},
        },
        {
            name    => '24-hour vs AM/PM (4AM)',
            pattern => '%Y-%m-%d %H %P',
            input   => '2015-01-02 4 PM',
            error =>
                qr{\QParsed an input with 24-hour and AM/PM values that do not match - "4" versus "PM"},
        },
        {
            name    => 'year vs century',
            pattern => '%Y-%m-%d %C',
            input   => '2015-01-02 19',
            error =>
                qr{\QParsed an input with year and century values that do not match - "2015" versus "19"},
        },
        {
            name    => 'year vs year-within-century',
            pattern => '%Y-%m-%d %y',
            input   => '2015-01-02 14',
            error =>
                qr{\QParsed an input with year and year-within-century values that do not match - "2015" versus "14"},
        },
        {
            name    => 'time zone offset vs time zone abbreviation',
            pattern => '%Y %z %Z',
            input   => '2015 -0500 AEST',
            error =>
                qr{\QParsed an input with time zone abbreviation and time zone offset values that do not match - "AEST" versus "-0500"},
        },
        {
            name    => 'epoch vs year',
            pattern => '%s %Y',
            input   => '42 2015',
            error =>
                qr{\QParsed an input with epoch and year values that do not match - "42" versus "2015"},
        },
        {
            name    => 'epoch vs month',
            pattern => '%s %m',
            input   => '42 12',
            error =>
                qr{\QParsed an input with epoch and month values that do not match - "42" versus "12"},
        },
        {
            name    => 'epoch vs day',
            pattern => '%s %d',
            input   => '42 13',
            error =>
                qr{\QParsed an input with epoch and day values that do not match - "42" versus "13"},
        },
        {
            name    => 'epoch vs day',
            pattern => '%s %H',
            input   => '42 14',
            error =>
                qr{\QParsed an input with epoch and hour values that do not match - "42" versus "14"},
        },
        {
            name    => 'epoch vs minute',
            pattern => '%s %M',
            input   => '42 15',
            error =>
                qr{\QParsed an input with epoch and minute values that do not match - "42" versus "15"},
        },
        {
            name    => 'epoch vs minute',
            pattern => '%s %S',
            input   => '42 16',
            error =>
                qr{\QParsed an input with epoch and second values that do not match - "42" versus "16"},
        },
        {
            name    => 'epoch vs hour (1-12)',
            pattern => '%s %I %P',
            input   => '42 4 PM',
            error =>
                qr{\QParsed an input with epoch and hour (1-12) values that do not match - "42" versus "4"},
        },
        {
            name    => 'epoch vs day of year',
            pattern => '%s %j',
            input   => '42 17',
            error =>
                qr{\QParsed an input with epoch and day of year values that do not match - "42" versus "17"},
        },
        {
            name    => 'month vs day of year',
            pattern => '%Y %m %j',
            input   => '2015 8 17',
            error =>
                qr{\QParsed an input with month and day of year values that do not match - "8" versus "17"},
        },
        {
            name    => 'day name vs date',
            pattern => '%Y %m %d %a',
            input   => '2015 8 17 Tuesday',
            error =>
                qr{\QParsed an input where the day name does not match the date - "Tuesday" versus "2015-08-17"},
        },
        {
            name    => 'day of week vs date',
            pattern => '%Y %m %d %u',
            input   => '2015 8 17 2',
            error =>
                qr{\QParsed an input where the day of week does not match the date - "2" versus "2015-08-17"},
        },
        {
            name    => 'day of week (Sunday as 0) vs date',
            pattern => '%Y %m %d %w',
            input   => '2015 8 17 2',
            error =>
                qr{\QParsed an input where the day of week (Sunday as 0) does not match the date - "2" versus "2015-08-17"},
        },
        {
            name    => 'iso week year vs date',
            pattern => '%Y %m %d %G',
            input   => '2015 8 17 2013',
            error =>
                qr{\QParsed an input where the ISO week year does not match the date - "2013" versus "2015-08-17"},
        },
        {
            name    => 'iso week year (without century) vs date',
            pattern => '%Y %m %d %g',
            input   => '2015 8 17 13',
            error =>
                qr{\QParsed an input where the ISO week year (without century) does not match the date - "13" versus "2015-08-17"},
        },
        {
            name    => 'iso week number vs date',
            pattern => '%Y %m %d %W',
            input   => '2015 8 17 15',
            error =>
                qr{\QParsed an input where the ISO week number (Monday starts week) does not match the date - "15" versus "2015-08-17"},
        },
        {
            name    => 'iso week number vs date',
            pattern => '%Y %m %d %U',
            input   => '2015 8 17 15',
            error =>
                qr{\QParsed an input where the ISO week number (Sunday starts week) does not match the date - "15" versus "2015-08-17"},
        },
        {
            name    => 'invalid time zone name',
            pattern => '%Y %O',
            input   => '2015 Dev/Null',
            error =>
                qr{\QThe Olson time zone name that was parsed does not appear to be valid, "Dev/Null"},
        },
        {
            name    => 'illegal date',
            pattern => '%Y-%m-%d',
            input   => '0000-00-00',
            error   => qr{\QParsed values did not produce a valid date},
        },
        {
            name    => 'illegal time',
            pattern => '%Y-%m-%d %H:%M',
            input   => '0000-00-00 26:99',
            error   => qr{\QParsed values did not produce a valid date},
        },
        {
            name    => 'February 29, 2013 - RT #110247',
            pattern => '%a %b %d %T %Y',
            input   => 'Wed Feb 29 12:02:28 2013',
            error   => qr{\QParsed values did not produce a valid date},
        },
        {
            name    => 'Failed word boundary check at beginning - GitHub #11',
            pattern => '%d-%m-%y',
            input   => '2016-11-30',
            strict  => 1,
            error   => qr{\QYour datetime does not match your pattern},
        },
        {
            name    => 'Failed word boundary check at end',
            pattern => '%d-%m-%y',
            input   => '30-11-2016',
            strict  => 1,
            error   => qr{\QYour datetime does not match your pattern},
        },
    );

    for my $test (@tests) {
        subtest( $test->{name}, sub { _test_error_handling($test) } );
    }
}

done_testing();

sub _test_error_handling {
    my $test = shift;

    my $parser = DateTime::Format::Strptime->new(
        pattern  => $test->{pattern},
        on_error => 'croak',
        strict   => $test->{strict},
    );

    like(
        exception { $parser->parse_datetime( $test->{input} ) },
        $test->{error},
        'croak error'
    );

    $parser = DateTime::Format::Strptime->new(
        pattern  => $test->{pattern},
        on_error => 'undef',
        strict   => $test->{strict},
    );

    my $dt = $parser->parse_datetime( $test->{input} );

    like(
        $parser->errmsg,
        $test->{error},
        'errmsg error '
    );

    is(
        $dt,
        undef,
        'no datetime object is returned when there is a parse error'
    );

    $parser = DateTime::Format::Strptime->new(
        pattern  => $test->{pattern},
        on_error => sub { die { e => $_[1] } },
        strict   => $test->{strict},
    );

    my $e = exception { $parser->parse_datetime( $test->{input} ) };
    like(
        $e->{e},
        $test->{error},
        'custom on_error'
    );
}
