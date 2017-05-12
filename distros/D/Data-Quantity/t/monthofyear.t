#!/usr/bin/perl 

use strict;
use Test;

BEGIN { plan tests => 3, todo => [] }

use Data::Quantity::Time::MonthOfYear;

ok( Data::Quantity::Time::MonthOfYear->new( 1 )->readable eq 'January' );
ok( Data::Quantity::Time::MonthOfYear->new( 3 )->readable eq 'March' );
ok( Data::Quantity::Time::MonthOfYear->new( 2 )->readable() eq 'February' );

