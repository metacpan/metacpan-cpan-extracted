#!/usr/bin/perl 

use strict;
use Test;

BEGIN { plan tests => 3, todo => [] }

use Data::Quantity::Number::Number;

ok( Data::Quantity::Number::Number->new( 1 )->readable eq '1' );
ok( Data::Quantity::Number::Number->new( 1024 )->readable eq '1,024' );
ok( Data::Quantity::Number::Number->new( 2843.93 )->readable eq '2,843.93' );

