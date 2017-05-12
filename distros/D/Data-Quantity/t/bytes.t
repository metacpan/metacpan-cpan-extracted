#!/usr/bin/perl 

use strict;
use Test;

BEGIN { plan tests => 3, todo => [] }

use Data::Quantity::Number::Bytes;

ok( Data::Quantity::Number::Bytes->new( 1 )->readable eq '1B' );
ok( Data::Quantity::Number::Bytes->new( 1024 )->readable eq '1KB' );
ok( Data::Quantity::Number::Bytes->new( 284393 )->readable eq '277.7KB' );

