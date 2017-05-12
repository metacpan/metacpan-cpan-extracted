#!/usr/bin/perl 

use strict;
use Test;

BEGIN { plan tests => 3, todo => [] }

use Data::Quantity::Size::Inches;

ok( Data::Quantity::Size::Inches->new( 1 )->readable eq '1"' );
ok( Data::Quantity::Size::Inches->new( 12 )->readable eq "1'" );
ok( Data::Quantity::Size::Inches->new( 25 )->readable eq "2'1\"" );

