#!/usr/bin/perl

# Formal testing for Class::Autouse.
# While this isn't a particularly exhaustive unit test like script, 
# it does test every known bug and corner case discovered. As new bugs
# are found, tests are added to this test script.
# So if everything works for all the nasty corner cases, it should all work
# as advertised... we hope ;)

use strict;
use File::Spec::Functions ':ALL';
use lib catdir('t', 'lib');
BEGIN {
	$|  = 1;
	$^W = 1;
        $Class::Autouse::DEBUG = 1;
}

use Test::More tests => 29;
use Scalar::Util 'refaddr';
use Class::Autouse ();





# Test the class_exists class detector
ok( Class::Autouse->class_exists( 'Class::Autouse' ), '->class_exists works for existing class' );
ok( ! Class::Autouse->class_exists( 'Class::Autouse::Nonexistant' ), '->class_exists works for non-existant class' );





#####################################################################
# Regression Test
# This should fail in 0.8, 0.9 and 1.0

# Does ->can for an autoused class correctly load the class and find the method.
my $class = 'D';
ok( refaddr(*UNIVERSAL::can{CODE}), "We know which version of UNIVERSAL::can we are using" );
is( refaddr(*UNIVERSAL::can{CODE}), refaddr($Class::Autouse::ORIGINAL_CAN),
	"Before autoloading, UNIVERSAL::can is in it's original state, and has been backed up");
is( refaddr(*UNIVERSAL::isa{CODE}), refaddr($Class::Autouse::ORIGINAL_ISA),
	"Before autoloading, UNIVERSAL::isa is in it's original state, and has been backed up");
ok( Class::Autouse->autouse( $class ), "Test class '$class' autoused ok" );
is( refaddr(*UNIVERSAL::can{CODE}), refaddr(*Class::Autouse::_can{CODE}),
	"After autoloading, UNIVERSAL::can has been correctly hijacked");
is( refaddr(*UNIVERSAL::isa{CODE}), refaddr(*Class::Autouse::_isa{CODE}),
	"After autoloading, UNIVERSAL::isa has been correctly hijacked");
ok( $class->can('method2'), "'can' found sub 'method2' in autoused class '$class'" );
ok( $Class::Autouse::LOADED{$class}, "'can' loaded class '$class' while looking for 'method2'" );
is( refaddr(*UNIVERSAL::can{CODE}), refaddr($Class::Autouse::ORIGINAL_CAN),
	"When all classes are loaded, UNIVERSAL::can reverts back to the original state");
is( refaddr(*UNIVERSAL::isa{CODE}), refaddr($Class::Autouse::ORIGINAL_ISA),
	"Whan all classes are loaded, UNIVERSAL::isa reverts back to the original state");

# Use the loaded hash again to avoid a warning
$_ = $Class::Autouse::LOADED{$class};





#####################################################################
# Regression Test
# This may fail below Class::Autouse 0.8. If the above tests fail, ignore any failure.

# Does ->can follow the inheritance tree correctly when finding a method.
ok( $class->can('method'), "'can' found sub 'method' in '$class' ( from parent class 'C' )" );





#####################################################################
# Regression Test
# This should fail below Class::Autouse 0.8

# If class 'F' isa 'E' and method 'foo' in F uses SUPER::foo, make sure it find the method 'foo' in E.
ok( Class::Autouse->autouse( 'E' ), 'Test class E autouses ok' );
ok( Class::Autouse->autouse( 'F' ), 'Test class F autouses ok' );
ok( F->foo eq 'Return value from E->foo', 'Class->SUPER::method works safely' );





#####################################################################
# Regression Test
# This should fail for Class::Autouse 0.8 and 0.9

# If an non package based class is empty, except for an ISA to an existing class,
# and method 'foo' exists in the parent class, UNIVERSAL::can SHOULD return true.
# After the addition of the UNIVERSAL::can replacement Class::Autouse::_can, it didn't.
# In particular, this was causing problems with MakeMaker.
@G::ISA = 'E';
ok( G->can('foo'), "_can handles the empty class with \@ISA case correctly" );

# Catch additional bad uses of _can early.
is( Class::Autouse::_can( undef, 'foo' ), undef,
	'Giving bad stuff to _can returns expected' );
is( Class::Autouse::_can( 'something/random/that/isnt/c/class', 'paths' ), undef,
	'Giving bad stuff to _can returns OK' );





#####################################################################
# Regression Test
# Class::Autouse 1.18 does not pass on errors incurred during ->can calls.

# This is expected behaviour and worked in 1.18 already.
ok( Class::Autouse->autouse( 'G' ),       'Test class G autouses ok' );
ok( Class::Autouse->autouse( 'H' ),       'Test class H autouses ok' );
my $coderef = G->can('foo');
is( ref($coderef), 'CODE',                'Good existant ->can autoloads correctly and returns a CODE ref' );
is( refaddr(&$coderef), refaddr(&G::foo), '->can returns the expected function' );
is( H->can('foo'), undef,                 'Good non-existant ->can autoloads correctly' );

use_ok( 'J' );
$coderef = 'foobar';
eval {
	J->can('foo');
};
like( $@, qr/^J\-\>can threw an exception/, 'A normal ->can call can throw an exception' );

# This initially failed in 1.18 and was fixed for 1.20
ok( Class::Autouse->autouse( 'I' ),       'Test class I autouses ok' );
$coderef = 'foobar';
eval {
	$coderef = I->can('foo');
};
like( $@, qr/^This is an expected error/, 'Bad existant ->can throws the expected error' );
is( $coderef, 'foobar',                   'Assigned value from autoloading ->can remains unchanged' );
