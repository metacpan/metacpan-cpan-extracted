
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.4;

BEGIN {
    use_ok( 'Astro::Montenbruck::Lunation', qw/:all/ );
}

subtest 'search_event' => sub {
    my @cases = (
        [ [1977, 2, 15], $NEW_MOON     , 2443192.65118, 120.96 ],
        [ [1965, 2,  1], $FIRST_QUARTER, 2438800.87026, 328.72 ],
        [ [1965, 2,  1], $FULL_MOON    , 2438807.52007, 66.39 ],
        [ [2044, 1,  1], $LAST_QUARTER , 2467636.49186, 218.47 ],
        [ [2019, 8, 21], $NEW_MOON     , 2458725.94287, 53.64 ],
        [ [2019, 8, 21], $FIRST_QUARTER, 2458732.63302, 151.31 ],
        [ [2019, 8, 21], $FULL_MOON    , 2458740.69049, 248.98 ],
        [ [2019, 8, 21], $LAST_QUARTER , 2458748.61252, 346.65 ],
    );

    for (@cases) {
        my ($date, $q, $exp_j, $exp_f) = @$_;
        my ($j, $f) = search_event($date, $q);
        delta_ok($j, $exp_j, sprintf('%s on %d-%d-%d', $q, @$date));
        delta_within($f, $exp_f, 0.2, sprintf('F on %d-%d-%d', @$date));
    }
    done_testing();
};

subtest 'lunar_phase' => sub {
    my @cases = (
        {
            date  => '2021-01-01',
            sun   => 281.16,
            moon  => 127.64,
            phase => $FULL_MOON,
            age   => 206.48
        },
        {
            date  => '2021-01-08',
            sun   => 288.29,
            moon  => 224.31,
            phase => $LAST_QUARTER,
            age   => 296.01
        },
        {
            date  => '2021-01-15',
            sun   => 295.43,
            moon  => 322.7,
            phase => $NEW_MOON,
            age   => 27.27
        },
        {
            date  => '2021-01-22',
            sun   => 302.56,
            moon  => 48.75,
            phase => $FIRST_QUARTER,
            age   => 106.19
        },        
        {
            date  => '2021-01-29',
            sun   => 309.67,
            moon  => 136.82,
            phase => $FULL_MOON,
            age   => 187.14
        }, 
        {
            date  => '2021-02-05',
            sun   => 316.77,
            moon  => 235.14,
            phase => $LAST_QUARTER,
            age   => 278.37
        },                      
        {
            date  => '2021-02-12',
            sun   => 323.86,
            moon  => 330.87,
            phase => $NEW_MOON,
            age   => 7.0
        },          
        {
            date  => '2021-02-19',
            sun   => 330.93,
            moon  => 56.51,
            phase => $WAXING_CRESCENT,
            age   => 85.58
        },             
        {
            date  => '2021-02-26',
            sun   => 337.98,
            moon  => 145.25,
            phase => $WAXING_GIBBOUS,
            age   => 167.27
        },               
        {
            date  => '2021-03-05',
            sun   => 345.0,
            moon  => 246.05,
            phase => $WANING_GIBBOUS,
            age   => 261.04
        },             
        {
            date  => '2021-03-12',
            sun   => 352.0,
            moon  => 339.73,
            phase => $WANING_CRESCENT,
            age   => 347.72
        },           
        {
            date  => '2021-03-19',
            sun   => 358.98,
            moon  => 64.52,
            phase => $WAXING_CRESCENT,
            age   => 65.54
        },   
        {
            date  => '2021-03-26',
            sun   => 5.92,
            moon  => 153.25,
            phase => $WAXING_GIBBOUS,
            age   => 147.38
        },            
        {
            date  => '2021-04-02',
            sun   => 12.84,
            moon  => 256.3,
            phase => $WANING_GIBBOUS,
            age   => 243.46
        },            
        {
            date  => '2021-04-09',
            sun   => 19.73,
            moon  => 349.09,
            phase => $WANING_CRESCENT,
            age   => 329.36
        },                 
    );

    for my $case(@cases) {
        my ($phase, $age, $days) = moon_phase(moon => $case->{moon}, sun => $case->{sun});
        delta_within($age, $case->{age}, 0.1, sprintf('%6.2f on %s', $case->{age}, $case->{date}));
        ok($phase eq $case->{phase}, sprintf('%s on %s', $case->{phase}, $case->{date}));
    }
};


done_testing();
