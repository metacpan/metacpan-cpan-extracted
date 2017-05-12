#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.05';

use Test::More tests => 110;

use_ok('DateTime::Event::Cron::Quartz');

use DateTime;
use Readonly;

sub make_datetime {
    return DateTime->new(
        year   => shift,
        month  => shift,
        day    => shift,
        hour   => shift,
        minute => shift,
        second => shift
    );
}

sub dcomp {
    is( shift->datetime, shift->datetime, shift );
    return;
}

#    SHORT FORMAT DESCRIPTION
#
#    * all fields (every)
#    - range
#    , additional
#    / increments  ( 0 == *)
#    L DOW DOM fields (last day OF ..)
#    W DOM field  (nearest weekday)
#    LW last dayweek of month
#    # DOW field (nth day of month)
#    C DOM DOW fields
#
#    Field Name              Allowed Values          Allowed Special Characters
#    ==========================================================================
#    Seconds                 0-59                    , - * /
#    Minutes                 0-59                    , - * /
#    Hours                   0-23                    , - * /
#    Day-of-month            1-31                    , - * ? / L W C
#    Month                   1-12 or JAN-DEC         , - * /
#    Day-of-Week             1-7 or SUN-SAT          , - * ? / L C #
#    Year (Optional)         empty, 1970-2099        , - * /
#
#
#    TESTS DATA
#
#    [CRONTAB VALUE, CURRENT_TIME, [NEXT_EVENT_TIMES], DESCRIPTION]
#

Readonly my $TESTS => [
    [
        '0 0 0 31 * ?',
        [ 2008, 1, 1, 0, 0, 0 ],
        [ [ 2008, 1, 31, 0, 0, 0 ], [ 2008, 3, 31, 0, 0, 0 ] ],
        'Last day of the month'
    ],

    [
        '0 0 0 1 3,6,9,12 ?',
        [ 2009, 12, 1, 16, 0, 8],
        [[ 2010, 3, 1, 0, 0 ,0], [2010, 6, 1, 0, 0 ,0], [2010, 9, 1, 0, 0 ,0]]
    ],

    [
        '0 10 14 ? JAN,FEB MON,WED 2010-2011',
        [ 2009, 7, 15, 7, 47, 8],
        [[ 2010, 1, 4, 14, 10 ,0], [2010, 1, 6, 14, 10, 0], [2010, 1, 11, 14, 10, 00]]
    ],
    
    [
        '0 0 3 ? * 5L',
        [ 2009, 8, 25, 11, 14, 06 ],
        [[2009, 8, 28, 3, 0, 0], [2009, 9, 25, 3, 0, 0], [2009, 10, 30, 3, 0, 0]],
        'Last friday of month'
    ],

    [
        '0 0 3 LW * ?',
        [ 2009, 8, 25, 11, 14, 06 ],
        [[2009, 8, 31, 3, 0, 0], [2009, 9, 30, 3, 0, 0], [2009, 10, 30, 3, 0, 0]],
        'Last workday of month'
    ],

    [
        '0 0 3 27W * ?',
        [ 2009, 6, 25, 11, 14, 06 ],
        [[2009, 6, 26, 3, 0, 0], [2009, 7, 27, 3, 0, 0], [2009, 8, 27, 3, 0, 0]],
        'Nearest workday to 27-th day'
    ],

    [
        '* * * ? * *',
        [ 2009, 12, 31, 23, 59, 58],
        [
         [ 2009, 12, 31, 23, 59, 59],
         [ 2010, 1, 1, 0, 0, 0],
         [ 2010, 1, 1, 0, 0, 1]
        ],
        'Each second'
    ],

    [
        '* * * ? * *',
        [ 2009, 12, 31, 23, 59, 58],
        [
         [ 2009, 12, 31, 23, 59, 59],
         [ 2010, 1, 1, 0, 0, 0],
         [ 2010, 1, 1, 0, 0, 1]
        ],
        'Each second'
    ],

    [
        '0 0 3 ? * 5',
        [ 2009, 6, 26, 11, 14, 06 ],
        [[2009, 7, 3, 3, 0, 0], [2009, 7, 10, 3, 0, 0]],
        'Each Friday at 3am'
    ],

    [
        '0 0 12 ? * *',
        [ 2008, 1, 1, 1, 1, 1 ],
        [ [ 2008, 1, 1, 12, 0, 0 ], [ 2008, 1, 2, 12, 0, 0 ] ],
        'Fire at 12pm (noon) every day'
    ],

    [
        '0 15 10 ? * *',
        [ 2008, 1, 1, 0, 0, 0 ],
        [ [ 2008, 1, 1, 10, 15, 0 ], [ 2008, 1, 2, 10, 15, 0 ] ],
        'Fire at 10:15am every day during the year 2005 (1)'
    ],

    [
        '0 10 14 ? * 1-2',
        [ 2009, 6, 1, 0, 0, 0 ],
        [
            [ 2009, 6, 1, 14, 10, 0 ],
            [ 2009, 6, 2, 14, 10, 0 ],
            [ 2009, 6, 8, 14, 10, 0 ]
        ],
        'Fire at 14:10 every Monday, Tuesday, Wednesday, Thursday and Friday'
    ],

    [
        '0 15 10 ? * *',
        [ 2008, 12, 30, 0, 0, 0 ],
        [
            [ 2008, 12, 30, 10, 15, 0 ],
            [ 2008, 12, 31, 10, 15, 0 ],
            [ 2009, 1,  1,  10, 15, 0 ]
        ],
        'Fire at 10:15am every day during the year 2005 (2)'
    ],

    [
        '0 0-2 14 ? * *',
        [ 2008, 1, 1, 0, 0, 0 ],
        [
            [ 2008, 1, 1, 14, 0, 0 ],
            [ 2008, 1, 1, 14, 1, 0 ],
            [ 2008, 1, 1, 14, 2, 0 ]
        ],
        'Fire every minute starting at 2pm and ending at 2:05pm, every day'
    ],

    [
        '0 10 14 ? * WED',
        [ 2009, 6, 2, 0, 0, 0 ],
        [ [ 2009, 6, 3, 14, 10, 0 ], [ 2009, 6, 10, 14, 10, 0 ] ],
        'Fire at 14:10 every Wednesday in the month of March'
    ],

    [
        '0 15 10 L * ?',
        [ 2009, 1, 1, 0, 0, 0 ],
        [ [ 2009, 1, 31, 10, 15, 0 ], [ 2009, 2, 28, 10, 15, 0 ] ],
        'Fire at 10:15am on the last day of every month'
    ],

    [
        '0 15 10 ? * 5L',
        [ 2009, 1, 1, 0, 0, 0 ],
        [
            [ 2009, 1, 30, 10, 15, 0 ],
            [ 2009, 2, 27, 10, 15, 0 ],
            [ 2009, 3, 27, 10, 15, 0 ]
        ],
        'Fire at 10:15am on the last Friday of every month'
    ],

    [
        '0 15 10 ? * 5#3',
        [ 2009, 1, 1, 0, 0, 0 ],
        [
            [ 2009, 1, 16, 10, 15, 0 ],
            [ 2009, 2, 20, 10, 15, 0 ],
            [ 2009, 3, 20, 10, 15, 0 ]
        ],
        'Fire at 10:15am on the third Friday of every month'
    ],

    [
        '0 */30 14 * * ?',
        [ 2008, 1, 1, 0, 0, 0 ],
        [
            [ 2008, 1, 1, 14, 0,  0 ],
            [ 2008, 1, 1, 14, 30, 0 ],
            [ 2008, 1, 2, 14, 0,  0 ]
        ],
        'Fire every 5 minutes starting at 2pm and ending at 2:55pm, every day'
    ],

    [
        '0 30 14,18 * * ?',
        [ 2008, 1, 1, 0, 0, 0 ],
        [
            [ 2008, 1, 1, 14, 30, 0 ],
            [ 2008, 1, 1, 18, 30, 0 ],
            [ 2008, 1, 2, 14, 30, 0 ]
        ],
        'Fire every 5 minutes starting at 2pm and ending at 2:55pm, '
          . 'AND fire every 5 minutes starting at 6pm and ending at 6:55pm, every day'
    ],

    # from DateTime::Event::Cron : cascade.t

    [
        '0 30 10,14,18 * * ?',
        [ 2003, 1, 1, 14, 40, 0 ],
        [
            [ 2003, 1, 1, 18, 30, 0 ],
            [ 2003, 1, 2, 10, 30, 0 ],
            [ 2003, 1, 2, 14, 30, 0 ]
        ],
        'Every 30th minute at 10,14,18 every day'
    ],

    [
        '0 0 12 10,15,20 * ?',
        [ 2003, 1, 15, 15, 0, 0 ],
        [ [ 2003, 1, 20, 12, 0, 0 ], [ 2003, 2, 10, 12, 0, 0 ] ],
        'Fired at 12:00 on 10,15,20-th of every month'
    ],

    [
        '0 0 12 ? * 2,4,6',
        [ 2003, 1, 16, 15, 0, 0 ],
        [ [ 2003, 1, 18, 12, 0, 0 ] ],
        'Fired on 12:00 on every 2,4,6 day of the week'
    ],

    [
        '0 0 0 15 5,7,9 ?',
        [ 2003, 7, 20, 0, 0, 0 ],
        [ [ 2003, 9, 15, 0, 0, 0 ] ],
        'Fired on midnight on 15-th day of 5,7,9 months'
    ],

    [
        '0 0 0 ? 5,7,9 3',
        [ 2003, 7, 31, 0, 0, 0 ],
        [ [ 2003, 9, 3, 0, 0, 0 ] ],
        'Fired on every 3-rd day of the week of 5,7,9 months'
    ],

    [
        '0 0 0 1 7 ?',
        [ 2003, 8, 30, 0, 0, 0 ],
        [ [ 2004, 7, 1, 0, 0, 0 ] ],
        'Fired on every 1st day of the 7-th month of each year'
    ],

    [
        '0 20 10,14,18 5,10,15 5,7,9 ?',
        [ 2003, 9, 15, 18, 30, 0 ],
        [ [ 2004, 5, 5, 10, 20, 0 ] ],
'Fired on 10,14,18 hours 20 minutes on every 5,10,15th days of 5,7,9-th months every year'
    ],

    # leapyear.t
    [
        '0 1 1 29 * ?',
        [ 2001, 2, 14, 15, 0, 0 ],
        [
            [ 2001, 3, 29, 1, 1, 0 ],
            [ 2001, 4, 29, 1, 1, 0 ],
            [ 2001, 5, 29, 1, 1, 0 ]
        ],
        'Feb 29 skip, non leap year'
    ],
    [
        '0 1 1 29 * ?',
        [ 1996, 2, 14, 15, 0, 0 ],
        [
            [ 1996, 2, 29, 1, 1, 0 ],
            [ 1996, 3, 29, 1, 1, 0 ],
            [ 1996, 4, 29, 1, 1, 0 ]
        ],
        'Feb 29 hit, leap year'
    ],
    [
        '0 1 1 31 * ?',
        [ 2001, 2, 14, 15, 0, 0 ],
        [
            [ 2001, 3, 31, 1, 1, 0 ],
            [ 2001, 5, 31, 1, 1, 0 ],
            [ 2001, 7, 31, 1, 1, 0 ]
        ],
        'Feb 31 skip, non leap year'
    ],

    [
        '0 1 1 1 * ?',
        [ 2001, 2, 14, 15, 0, 0 ],
        [
            [ 2001, 3, 1, 1, 1, 0 ],
            [ 2001, 4, 1, 1, 1, 0 ],
            [ 2001, 5, 1, 1, 1, 0 ]
        ],
        'Mar 1 from Feb, non leap year'
    ],

    [
        '0 12 21 ? * 7',
        [ 2002, 9, 9, 15, 10, 0 ],
        [
            [ 2002, 9, 15, 21, 12, 0 ],
            [ 2002, 9, 22, 21, 12, 0 ],
            [ 2002, 9, 29, 21, 12, 0 ]
        ],
        'Every sunday once a week'
    ],

    [
        '0 12 21 ? * 2,4',
        [ 2002, 9, 9, 15, 10, 0 ],
        [
            [ 2002, 9, 10, 21, 12, 0 ],
            [ 2002, 9, 12, 21, 12, 0 ],
            [ 2002, 9, 17, 21, 12, 0 ]
        ],
        'every tues/thurs'
    ],

    [
        '0 42 * * * ?',
        [ 1987, 6, 21, 9, 51, 0 ],
        [
            [ 1987, 6, 21, 10, 42, 0 ],
            [ 1987, 6, 21, 11, 42, 0 ],
            [ 1987, 6, 21, 12, 42, 0 ]
        ],
        'every hour'
    ],

    [
        '0 42 13,15,22,23 * * ?',
        [ 1987, 6, 21, 17, 51, 0 ],
        [
            [ 1987, 6, 21, 22, 42, 0 ],
            [ 1987, 6, 21, 23, 42, 0 ],
            [ 1987, 6, 22, 13, 42, 0 ]
        ],
        'comma-separated hour list'
    ],

    [
        '0 * 17 * * ?',
        [ 1987, 6, 21, 17, 57, 59 ],
        [
            [ 1987, 6, 21, 17, 58, 0 ],
            [ 1987, 6, 21, 17, 59, 0 ],
            [ 1987, 6, 22, 17, 0,  0 ]
        ],
        'every minute of 5pm'
    ],

    [
        '0 2,32 * * * ?',
        [ 1987, 6, 21, 17, 57, 59 ],
        [
            [ 1987, 6, 21, 18, 2,  0 ],
            [ 1987, 6, 21, 18, 32, 0 ],
            [ 1987, 6, 21, 19, 2,  0 ]
        ],
        'comma separated minute list'
    ],

    [
        '0 0 13 29 2 ?',
        [ 1995, 4, 12, 5, 30, 0 ],
        [
            [ 1996, 2, 29, 13, 0, 0 ],
            [ 2000, 2, 29, 13, 0, 0 ],
            [ 2004, 2, 29, 13, 0, 0 ]
        ],
        'infrequent (feb 29) job'
    ]
];

# run cron 'next' date checks
foreach my $test ( @{$TESTS} ) {

    my ( $crontab, $current, $after_dates, $desc ) = @{$test};

    my $event = DateTime::Event::Cron::Quartz->new($crontab);

    $current = make_datetime( @{$current} );

    # check 'after' values
    for my $after ( @{$after_dates} ) {
        my $date_cmp = make_datetime( @{$after} );
        my $next     = $event->get_next_valid_time_after($current);
        dcomp( $next, $date_cmp, $desc );
        $current = $next;
    }
}

# run validation tests
# [CRON_EXPRESSION, DESCRIPTION]

Readonly my $VALIDATION_TESTS => [
    [ '# commentary',            'reject comment line' ],
    [ '* * *',                   'reject partial line' ],
    [ q//,                       'reject empty line' ],
    [ 'ENV_VAR=123',             'reject environment variable line' ],
    [ 'hey exciting things * *', 'reject malformed entries' ],
    [ '0 69 * ? * *',            'reject minute out of range' ],
    [ '0 * 24 ? * *',            'reject hour out of range' ],
    [ '0 * * 77 * ?',            'reject day out of range high' ],
    [ '* * * 0 * ?',             'reject day out of range low' ],
    [ '0 * * * 20 * ?',          'reject month out of range high' ],
    [ '* * * * 0 * ?',           'reject month out of range low' ],
    [ '* * * ? * 11',            'reject dow out of range' ]
];

foreach my $test ( @{$VALIDATION_TESTS} ) {
    ok( !DateTime::Event::Cron::Quartz->is_valid_expression( $test->[0] ),
        $test->[1] );
}
