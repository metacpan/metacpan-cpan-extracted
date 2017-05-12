#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use lib grep { -d } qw(../lib ./lib ./t/lib);
use Test::Easy qw(deep_ok);

use Array::Sticky::INC;
BEGIN { Array::Sticky::INC->make_sticky }

use lib 'volcano';
isnt( $INC[0], 'volcano' );
ok( 1 == grep { $_ eq 'volcano' } @INC );

unshift @INC, 'tornado';
isnt( $INC[0], 'tornado' );
ok( 1 == grep { $_ eq 'tornado' } @INC );
