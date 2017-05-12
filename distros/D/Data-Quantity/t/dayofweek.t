#!/usr/bin/perl 

use strict;
use Test;

BEGIN { plan tests => 3, todo => [] }

use Data::Quantity::Time::DayOfWeek;

ok( Data::Quantity::Time::DayOfWeek->new( 1 )->readable eq 'Monday' );
ok( Data::Quantity::Time::DayOfWeek->new( 3 )->readable eq 'Wednesday' );
ok( Data::Quantity::Time::DayOfWeek->new( 2 )->readable('short') eq 'Tue' );

