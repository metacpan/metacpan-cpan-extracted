#!perl

use 5.010;
use strict;
use warnings;

use App::datecalc;
use Test::Exception;
use Test::More 0.98;

my $calc = App::datecalc->new;

subtest 'date literals' => sub {
    like($calc->eval('2014-05-20'), qr/\A2014-05-20#/, 'YYYY-MM-DD');
    dies_ok { $calc->eval('2014-02-29') } 'invalid YYYY-MM-DD -> dies';

    like($calc->eval('today'), qr/\A\d{4}-\d{2}-\d{2}#/, 'today');
    like($calc->eval('yesterday'), qr/\A\d{4}-\d{2}-\d{2}#/, 'yesterday');
    like($calc->eval('tomorrow'), qr/\A\d{4}-\d{2}-\d{2}#/, 'tomorrow');
};

subtest 'duration literals' => sub {
    dies_ok { $calc->eval('P2H') } 'invalid ISO -> dies';
    dies_ok { $calc->eval('2 days 2 week') } 'invalid natural -> dies';

    is($calc->eval('P2D'), 'P2D', 'ISO 1');
    is($calc->eval('P10DT1H2M'), 'P1W3DT1H2M', 'ISO 2');

    is($calc->eval('3 weeks'), 'P3W', 'natural 1');
    is($calc->eval('2d10h'), 'P2DT10H', 'natural 2');
};

subtest 'datetime literals' => sub {
    # currently we don't show time
    like($calc->eval('now'), qr/\A\d{4}-\d{2}-\d{2}#/, 'now');
};

subtest 'date addition/subtraction with duration' => sub {
    like($calc->eval('2014-05-20 + 20d'), qr/\A2014-06-09#/);
    like($calc->eval('2014-05-20 - P20D'), qr/\A2014-04-30#/);
};

subtest 'date subtraction with date' => sub {
    is($calc->eval('2014-05-20 - 2014-03-03'), 'P11W1D');
};

subtest 'duration addition/subtraction with duration' => sub {
    is($calc->eval('P1D + 30 mins 45s'), 'P1DT30M45S');
};

subtest 'duration multiplication/division with number' => sub {
    is($calc->eval('P1D * 2'), 'P2D');
    is($calc->eval('P2D / 2'), 'P1D');
    is($calc->eval('2 * P5D'), 'P1W3D');
};

subtest 'number arithmetics' => sub {
    is($calc->eval('2+3'), '5');
    is($calc->eval('1*2*3*4*5'), '120');
    is($calc->eval('7/2'), '3.5');
    is($calc->eval('2**2**3'), '256');
    is($calc->eval('4-5'), '-1');
    is($calc->eval('2*3 * P1D'), 'P6D');
    is($calc->eval('+-+5'), '-5');
};

subtest 'numeric functions' => sub {
    is($calc->eval('abs(-1)'), 1);
    is($calc->eval('round(1.2)'), 1);
    is($calc->eval('round(1.6)'), 2);
};
subtest 'date functions' => sub {
    is($calc->eval('year(2014-05-21)'), 2014);
    is($calc->eval('month(2014-05-21)'), 5);
    is($calc->eval('day(2014-05-21)'), 21);
    is($calc->eval('dow(2014-05-21)'), 3);
    is($calc->eval('quarter(2014-05-21)'), 2);
    is($calc->eval('doy(2014-05-21)'), 141);
    is($calc->eval('wom(2014-05-21)'), 4);
    is($calc->eval('woy(2014-05-21)'), 21);
    is($calc->eval('doq(2014-05-21)'), 51);

    #is($calc->eval('hour(2014-05-21)'), );
    #is($calc->eval('minute(2014-05-21)'), );
    #is($calc->eval('second(2014-05-21)'), );
};

subtest 'duration functions' => sub {
    is($calc->eval('years(P2Y13M)'), 3);
    is($calc->eval('months(P2Y13M)'), 1);
    is($calc->eval('weeks(P7D)'), 1);
    is($calc->eval('days(P8D)'), 1);
    is($calc->eval('totdays(P8D)'), 8);

    is($calc->eval('hours(PT8H)'), 8);
    is($calc->eval('minutes(PT13M)'), 13);
    is($calc->eval('seconds(PT70S)'), 70);
};

DONE_TESTING:
done_testing;
