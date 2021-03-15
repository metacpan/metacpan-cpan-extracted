# $Id: parse_interval.t 3687 2007-05-27 15:32:27Z lestrrat $
use strict;
use Test::More;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

my @positive_data;
my @negative_data;

BEGIN
{
    @negative_data = (
        '12:34:00 1 week 42 seconds',
        "2 hello",
        "hello",
        "-days",
    );

    @positive_data = (
        [ '098:08:00' => DateTime::Duration->new( hours => 98, minutes => 8, ) ],
        [ '1:08' => DateTime::Duration->new( hours => 1, minutes => 8, ) ],
        [ '3 days 1:08' => DateTime::Duration->new( days => 3, hours => 1, minutes => 8, ) ],
        [ '1:08:00' => DateTime::Duration->new( hours => 1, minutes => 8, ) ],
        [ '-012:00:00' => DateTime::Duration->new( hours => -12, ) ],
        [ '00:00:00' => DateTime::Duration->new() ],
        [ '-08:08:00' => DateTime::Duration->new( hours => -8, minutes => -8) ],
        [ '-98:08:00' => DateTime::Duration->new( hours => -98, minutes => -8) ],
        [ '-100:33:00' => DateTime::Duration->new( hours => -100, minutes => -33) ],
        [ '100:33:00' => DateTime::Duration->new( hours => 100, minutes => 33) ],
        [ '01:00:00'  => DateTime::Duration->new( hours => 1 )  ],
        [ '-08:00:00' => DateTime::Duration->new( hours => -8 ) ],
        [ '-1 days'   => DateTime::Duration->new(days => -1)    ],
        [ '-23:59'    => DateTime::Duration->new(hours => -23, minutes => -59) ],
        [ '-1 days -00:01' => DateTime::Duration->new( days => -1, minutes => -1) ],
        [ '-1 days -20:30:56.123456' => DateTime::Duration->new( 
                days => -1, 
                minutes => -1230,  # = 20 * 60 + 30
                seconds => -56,
                nanoseconds => -123456000,
            ),
        ],
        [ '1 mon -1 days' => DateTime::Duration->new(months => 1)->add(days => -1) ],
        [ '1 day 1 month' => DateTime::Duration->new(months => 1)->add(days => 1) ],
        [ '1 month -1 days' => DateTime::Duration->new(months => 1)->add(days => -1) ],
        [ '@ 1 mon -1 days' => DateTime::Duration->new(months => 1)->add(days => -1) ],
        [ '@ 1 month -1 days' => DateTime::Duration->new(months => 1)->add(days => -1) ],
        [ '-1 days +02:03:00' => DateTime::Duration->new(days => -1)
              ->add(
                  hours  => 2,
                  minutes => 3,
              )
        ],
        ['9 years 1 mon -12 days +13:14:00' => DateTime::Duration->new(
            years   => 9,
            months  => 1,
            hours   => 13,
            minutes => 14,
        )->add(days => -12)],
        [ '@ 1 day ago' => DateTime::Duration->new( days => -1 )],
        [ '@ 1 day 10 mins' => DateTime::Duration->new( days => 1, minutes => 10 )],
        [ '@ 23 hours 59 mins ago' => DateTime::Duration->new(
            hours => -23,
            minutes => -59
        )],
        [ '@ 1 day 1 min ago' => DateTime::Duration->new( days => -1, minutes => -1 )],
        [ '10 days' => DateTime::Duration->new(days => 10 ) ],
        [ '34 years' => DateTime::Duration->new(years => 34 )],
        [ '3 mon' => DateTime::Duration->new(months => 3 )],
        [ '3 mons' => DateTime::Duration->new(months => 3 )],
        [ '3 month' => DateTime::Duration->new(months => 3 )],
        [ '3 months' => DateTime::Duration->new(months => 3 )],
        [ '-00:00:14' => DateTime::Duration->new(seconds => -14 )],
        [ '1 day 02:03:04' => DateTime::Duration->new(
            days => 1,
            hours => 2,
            minutes => 3,
            seconds => 4,
        )],
    
        [ '5 mons 12:00:00' => DateTime::Duration->new( months => 5, hours => 12) ],
        [ '@ 1 min' => DateTime::Duration->new(minutes => 1 )],
        [ '@ 1 mins' => DateTime::Duration->new(minutes => 1 )],
        [ '@ 1 minute' => DateTime::Duration->new(minutes => 1 )],
        [ '@ 1 minutes' => DateTime::Duration->new(minutes => 1 )],
        [ '@ 5 hours' => DateTime::Duration->new( hours => 5 )],
        [ '@ 34 years' => DateTime::Duration->new(years => 34 )],
        [ '@ 3 mons' => DateTime::Duration->new(months => 3 )],
        [ '@ 14 sec ago' => DateTime::Duration->new( seconds => -14 )],
        [ '@ 14 secs ago' => DateTime::Duration->new( seconds => -14 )],
        [ '@ 14 second ago' => DateTime::Duration->new( seconds => -14 )],
        [ '@ 14 seconds ago' => DateTime::Duration->new( seconds => -14 )],
        [ '@ 1 day 2 hours 3 mins 4 secs' => DateTime::Duration->new(
            days => 1,
            hours => 2,
            minutes => 3,
            seconds => 4,
        )],
    
        [ '@ 5 mons 12 hours' => DateTime::Duration->new( hours => 12, months => 5) ],
        [ '@ 4541 years 4 mons 4 days 17 mins 31 secs' => DateTime::Duration->new(
            years => 4541,
            months => 4,
            days => 4,
            minutes => 17,
            seconds => 31,
        )],
    
        [ '@ 6 mons 5 days 4 hours 3 mins 2 secs' => DateTime::Duration->new(
            months => 6,
            days => 5,
            hours => 4,
            minutes => 3,
            seconds => 2,
        )],

        [ '1 days 02:03:00 ago' => DateTime::Duration->new(
            days => -1,
            hours => -2,
            minutes => -3,
        )],

        [ '1 millennium' => DateTime::Duration->new( years => 1000 )],
        [ '2 millennia' => DateTime::Duration->new( years => 2000 )],
        [ '3 millenniums' => DateTime::Duration->new( years => 3000 )],
        [ '1 mil' => DateTime::Duration->new( years => 1000 )],
        [ '2 mils' => DateTime::Duration->new( years => 2000 )],
        
        [ '1 century' => DateTime::Duration->new( years => 100 )],
        [ '2 centuries' => DateTime::Duration->new( years => 200 )],
        [ '1 cent' => DateTime::Duration->new( years => 100 )],
        [ '2 c' => DateTime::Duration->new( years => 200 )],
        
        [ '1 decade' => DateTime::Duration->new( years => 10 )],
        [ '2 decades' => DateTime::Duration->new( years => 20 )],
        [ '1 dec' => DateTime::Duration->new( years => 10 )],
        [ '2 decs' => DateTime::Duration->new( years => 20 )],

        [ '1 year' => DateTime::Duration->new( years => 1 )],
        [ '2 years' => DateTime::Duration->new( years => 2 )],
        [ '1 y' => DateTime::Duration->new( years => 1 )],
        [ '1 yr' => DateTime::Duration->new( years => 1 )],
        [ '2 yrs' => DateTime::Duration->new( years => 2 )],
        
        [ '1 mil 9 c 6 decade 2 yr' => DateTime::Duration->new( years => 1962 )],

        [ '1 month' => DateTime::Duration->new( months => 1 )],
        [ '2 months' => DateTime::Duration->new( months => 2 )],
        [ '1 mon' => DateTime::Duration->new( months => 1 )],
        [ '2 mons' => DateTime::Duration->new( months => 2 )],
        
        [ '1 week' => DateTime::Duration->new( weeks => 1 )],
        [ '2 weeks' => DateTime::Duration->new( weeks => 2 )],
        [ '1 w' => DateTime::Duration->new( weeks => 1 )],
        
        [ '1 day' => DateTime::Duration->new( days => 1 )],
        [ '2 days' => DateTime::Duration->new( days => 2 )],
        [ '1 d' => DateTime::Duration->new( days => 1 )],
        
        [ '1 mil 2 c 4 decade 8 yr 9 months 18 d ' => DateTime::Duration->new( years => 1248, months => 9, days => 18 )],
        [ '12 yr 42 w' => DateTime::Duration->new( years => 12, weeks => 42 )],
        [ '12:34:56 1 week' => DateTime::Duration->new( weeks => 1, hours => 12, minutes => 34, seconds => 56)],
    );

    plan tests => @negative_data + @positive_data + 1;
    use_ok 'DateTime::Format::Pg' or die;
}

{ # Positive data
    for my $compare (@positive_data) {
        ok !DateTime::Duration->compare(
            DateTime::Format::Pg->parse_duration($compare->[0]),
            $compare->[1]
        ), "'$compare->[0]'"
            or diag 
                Dumper [
                    { DateTime::Format::Pg->parse_duration($compare->[0])->deltas },
                    { $compare->[1]->deltas }
                ]
        ;
    }
}

{ # Negative data
    for my $data (@negative_data) {
        ok(! eval { DateTime::Format::Pg->parse_duration($data) } && $@, "'$data' fails to parse");
    }
}
