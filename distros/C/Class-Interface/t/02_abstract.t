#!perl -wT

use strict;

BEGIN {
  ($ENV{PWD}) = $ENV{PWD} =~ /(.*)/;
  require "$ENV{PWD}/test-lib/setup.pl";
}

use Test::More tests => 4;

# is the abstract in test-lib a true abstract?

use Car::AbstractFactory;

# has the voodoo been setup?
can_ok( "Car::AbstractFactory", "__get_abstract_methods__" );

# get the methods.
my @methods = Car::AbstractFactory::__get_abstract_methods__;

if ( ok( ( !grep { !defined $_  } @methods ), 'required method published' ) ) {
  is( $methods[0], "createCar", "method checks out" );
  is( $#methods, 0, "only the abstract method is published");

} else {
  BAIL_OUT("Abstract does not specify it's methods. No use for further tests")

}


1;

