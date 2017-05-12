#!/usr/bin/perl

use Test;
BEGIN { plan tests => 3 }

use DBIx::SQLEngine;
ok( 1 );

eval "use DBIx::SQLEngine 0.001;";
ok( ! $@ );

eval "use DBIx::SQLEngine 2.0;";
ok( $@ );
