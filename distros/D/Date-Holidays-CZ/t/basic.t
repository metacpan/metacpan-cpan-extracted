#!perl
use 5.010;
use strict;
use warnings;

use Data::Dumper;
use Date::Holidays::CZ qw( holidays );
use Test::More;

my $holidays;

note( 'Good Friday was added as of 2016' );
$holidays = holidays( YEAR => 2016, FORMAT => '%Y-%m-%d', WEEKENDS => 1 );
ok( grep { $_ eq '2016-03-25' } @$holidays, "Good Friday 2016" );
ok( grep { $_ eq '2016-03-27' } @$holidays, "Easter Sunday 2016" );
ok( grep { $_ eq '2016-03-28' } @$holidays, "Easter Monday 2016" );
ok( grep { $_ eq '2016-12-25' } @$holidays, "Christmas Day 2016" );

note( 'In 2015, Good Friday was not a State holiday' );
$holidays = holidays( YEAR => 2015, FORMAT => '%Y-%m-%d', WEEKENDS => 1 );
ok( ! grep { $_ eq '2015-04-03' } @$holidays, "Good Friday 2015" );
ok( grep { $_ eq '2015-04-05' } @$holidays, "Easter Sunday 2015" );
ok( grep { $_ eq '2015-04-06' } @$holidays, "Easter Monday 2015" );
ok( grep { $_ eq '2015-12-25' } @$holidays, "Christmas Day 2015" );

done_testing;
