#!perl -wT

use strict;

BEGIN {
  ($ENV{PWD}) = $ENV{PWD} =~ /(.*)/;
  require "$ENV{PWD}/test-lib/setup.pl";
}

use Test::More tests => 8;

# is it usable
use_ok("Class::Interface");

# is the interface in test-lib a true interface?

use Car::Interface;

# has the voodoo been setup?
can_ok( "Car::Interface", "__get_interface_methods__" );
can_ok( "Car::Interface", "import" );

# get the methods.
my @methods = Car::Interface::__get_interface_methods__;

if ( ok( ( !grep { !defined $_  } @methods ), 'required methods published' ) ) {
  is( $methods[0], "openDoors", "method 1 checks out" );
  is( $methods[1], "closeDoors", "method 2 checks out");
  is( $methods[2], "start", "method 3 checks out");
  is( $methods[3], "stop", "method 4 checks out");

} else {
  BAIL_OUT("Interface does not specify it's methods. No use for further tests")

}


1;

