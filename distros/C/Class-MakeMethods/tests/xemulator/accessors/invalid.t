#!/usr/bin/perl

##
## Tests for invalid accessors
##

#use blib;
use strict;
use warnings;

BEGIN {
  eval q{ local $SIG{__DIE__}; require Test::More; 1 };
  if ( $@ ) {
    plan( tests => 1 );
    print "Skipping test on this platform (test requires Test::More).\n";
    ok( 1 );
    exit 0;
  }
}

use Test::More tests => 5;
use Carp;

BEGIN { use_ok("Class::MakeMethods::Emulator::accessors") };
BEGIN { import Class::MakeMethods::Emulator::accessors '-take_namespace' };

## invalid accessor names
do {
    eval { import accessors $_ };
    ok( $@, "invalid accessor - $_" );
} for (qw( DESTROY AUTOLOAD 1notasub @$%*&^';\/ ));
