#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::Composers' );

ok( defined &Brick::Bucket::__compose_satisfy_any,
	"__compose_satisfy_any defined"
	);

ok( defined &Brick::Bucket::__or,
	"__or defined"
	);
