#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Time::Piece qw/ :override /;
use Time::Seconds qw/ ONE_DAY ONE_MINUTE ONE_HOUR/;

require_ok('Astro::Coords');

# Simple test of calculate method
my $c = new Astro::Coords( ra => 0.0, dec => 0.0, type => 'j2000' );

# Start, end and increment
my $start = gmtime;
my $end = $start + ONE_DAY;
my $inc = ONE_HOUR;

my @results = $c->calculate( start=> $start,
                             end => $end,
                             inc => $inc,
                             units => 'deg');

is(scalar(@results), 25 , "Test return count");

is($results[0]->{time}->epoch, $start->epoch,"Match start epoch");
is($results[-1]->{time}->epoch, $end->epoch,"Match end epoch");
