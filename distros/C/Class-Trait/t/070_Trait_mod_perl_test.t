#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

# NOTE:

# This test proves that traits can work under mod_perl, if care is taken about
# how things are loaded. All traits should be imported from within your
# startup file, and then the Class::Trait->initialize() method should be
# called after all are loaded. This should result in the correct behavior.

my $warn;
local $SIG{__WARN__} = sub { $warn = shift };

eval "use BasicTrait;";

ok ! defined $warn, 'mod_perl should no longer warn on startup';
ok( BasicTrait->does("TSimple"), '.. BasicTrait is TSimple' );
