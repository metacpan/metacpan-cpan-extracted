use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;
use Test::Exception;

use DateTime;
use Date::LibICal;

my @examples = (
    {
        rule   => 'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO',
        result => [
            map {
                DateTime->new( year => 2013, month => 1, day => $_ );
            } qw(7 14 21 28)
        ],
        start  => DateTime->new(
            year  => 2013,
            month => 1,
            day   => 1,
        ),
    },
    {
        rule   => 'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO,2SO',
        result => [
            map {
                DateTime->new( year => 2013, month => 1, day => $_ );
            } qw(7 12 14 21 28)
        ],
        start  => DateTime->new(
            year  => 2013,
            month => 1,
            day   => 1,
        ),
    },
);

plan tests => 4 + 2 * scalar @examples;

throws_ok {
    Date::LibICal::expand_recurrence(
        'broken rule',
    );
}
qr{\A\QError during extending ical: MALFORMEDDATA: An input string was not correctly formed or a component has missing or extra properties\E}xms,
'invalid rules end in exceptions';

lives_ok {
    Date::LibICal::expand_recurrence(
        'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO',
    );
} 'Date::LibICal::expand_recurrence(rule, [start?, [count?]]) works';
lives_ok {
    Date::LibICal::expand_recurrence(
        'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO',
        0,
    );
} 'Date::LibICal::expand_recurrence(rule, start, [count?]) works';
lives_ok {
    Date::LibICal::expand_recurrence(
        'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO',
        0,
        1,
    );
} 'Date::LibICal::expand_recurrence(rule, start, count) works';

for my $example_ref ( @examples ) {
    is_deeply
        [
            map {
                DateTime->from_epoch( epoch => $_ );
            }
            Date::LibICal::expand_recurrence(
                $example_ref->{rule},
                $example_ref->{start}->epoch,
            )
        ],
        $example_ref->{result},
        "$example_ref->{rule} is correct";

    is_deeply
        [
            map {
                DateTime->from_epoch( epoch => $_ );
            }
            Date::LibICal::expand_recurrence(
                $example_ref->{rule},
                $example_ref->{start}->epoch,
                1,
            )
        ],
        [
            $example_ref->{result}->[0],
        ],
        "$example_ref->{rule} is correct with max count=1";
}
