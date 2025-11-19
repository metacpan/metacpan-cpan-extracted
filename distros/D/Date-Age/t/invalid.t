use strict;
use warnings;

use Test::Most tests => 3;

use_ok('Date::Age', qw(describe details));

dies_ok(sub { describe('2001-02-29', '2015-11-17') }, '2001 was not a leap year');
dies_ok(sub { details('1943-13-01', '2016-01-01') }, 'Trap that there are not 13 months in a year');
