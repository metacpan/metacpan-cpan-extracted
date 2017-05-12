#!/usr/bin/perl

# Tests the class inherited from traited class which trait uses SUPER

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

use Employee;

my $pt = PersonWithTitle->new;
my $e  = Employee->new;
my $p  = Person->new;

is( $pt->name, 'Mgr. George Richardson' );
is( $p->name,  'George Richardson' );
is( $e->name,  'Mgr. George Richardson' );

