#!/usr/bin/perl

use strict;
use warnings;

use Data::Validate::Chemistry qw( is_CAS_number );
use Test::More tests => 2;

ok( !is_CAS_number(   '1-2-3' ),   '"1-2-3" is not a CAS number' );
ok( !is_CAS_number( '111-2-3' ), '"111-2-3" is not a CAS number' );
