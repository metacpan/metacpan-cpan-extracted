#!/usr/bin/perl

use strict;
use warnings;

use Data::Validate::Chemistry qw( is_CAS_number );
use Test::More tests => 4;

ok( is_CAS_number( '7732-18-5' ), '"7732-18-5" is CAS number for water' );
ok( is_CAS_number(   '51-43-4' ),   '"51-43-4" is CAS number for L-epinephrine' );
ok( is_CAS_number(  '150-05-0' ),  '"150-05-0" is CAS number for D-epinephrine' );
ok( is_CAS_number(  '329-65-7' ),  '"329-65-7" is CAS number for DL-epinephrine' );
