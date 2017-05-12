#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

use Data::Ovulation;

ok( DELTA_FERTILE_DAYS,         "DELTA_FERTILE_DAYS" );
ok( DELTA_OVULATION_DAYS,       "DELTA_OVULATION_DAYS" );
ok( DELTA_NEXT_CYCLE,           "DELTA_NEXT_CYCLE" );

