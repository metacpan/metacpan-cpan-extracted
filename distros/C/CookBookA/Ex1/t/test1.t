#!perl -w

use strict;
require CookBookA::Ex1;
#use ExtUtils::Peek 'Dump';

my $lastcase = 9;
print "1..$lastcase\n";

######################################################################
# Demonstrate the base class.


{ # Check scoping
	no strict 'vars';
	package CookBookA::Ex1C;
	@ISA = 'CookBookA::Ex1';
	sub DESTROY { print "ok 1\n"; CookBookA::Ex1::DESTROY(@_) }
	my $a = CookBookA::Ex1C->new;
}
print "ok 2\n";

@CookBookA::Ex1A::ISA = 'CookBookA::Ex1';
sub CookBookA::Ex1A::DESTROY { print "ok $lastcase\n"; CookBookA::Ex1::DESTROY(@_) }

my $a = CookBookA::Ex1A->new;
my $x;

$x = $a->blue;
print( (($x == 42)? "ok ": "not ok "), "3\n" );

$a->set_blue( 24 );
$x = $a->blue;
print( (($x == 24)? "ok ": "not ok "), "4\n" );

######################################################################
# Use the unblessed opaque object


my $c = CookBookA::Ex1B::newEx1B();

$x = CookBookA::Ex1B::get_blue( $c );
print( (($x == 142)? "ok ": "not ok "), "5\n" );

# show that Ex1B doesn't care about blessedness
$x = CookBookA::Ex1B::get_blue( $a );
print( (($x == 24)? "ok ": "not ok "), "6\n" );

# show that Ex1 does care about blessedness
{
	local $SIG{'__WARN__'} = sub { print "ok 7\n" };
	$x = CookBookA::Ex1::blue($c);
	print( (( $x )? "not ok ": "ok "), "8\n" ); # careful, reversed.
}
CookBookA::Ex1B::freeEx1B( $c );
