#!perl -w

use strict;

my $lastcase = 7;
print "1..$lastcase\n";
require CookBookA::Ex7;

######################################################################
# Demonstrate the base class.

{ # Check scoping
	no strict 'vars';
	package CookBookA::Ex7C;
	@ISA = 'CookBookA::Ex7';
	sub DESTROY { print "ok 1\n"; CookBookA::Ex7::DESTROY(@_) }
	my $a = CookBookA::Ex7C->new;
}
print "ok 2\n";

@CookBookA::Ex7A::ISA = 'CookBookA::Ex7';
sub CookBookA::Ex7A::DESTROY { print "ok $lastcase\n"; CookBookA::Ex7::DESTROY(@_) }

my $a = CookBookA::Ex7A->new;
my $x;

$x = $a->blue;
print( (($x == 42)? "ok ": "not ok "), "3\n" );

$a->set_blue( 24 );
$x = $a->blue;
print( (($x == 24)? "ok ": "not ok "), "4\n" );

$x = $a->red;
print( (($x eq 'gurgle')? "ok ": "not ok "), "5\n" );
#print "x($x)\n";

$a->set_red( 'achoo' );
$x = $a->red;
print( (($x eq 'achoo')? "ok ": "not ok "), "6\n" );
