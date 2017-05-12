#!perl -w

print "1..11\n";

use strict;
require CookBookA::Ex4;

my $a;
my $b;
my $x;

######################################################################
# First, work with the base class.

$a = CookBookA::Ex4->new;

# Show that the C code can read a array entry.
$a->[0] = 'Right';
$x = $a->pop_val;
print( (($x eq 'Right')? "ok ": "not ok "), "1\n" );

# What happens when the entry doesn't exist?
$x = $a->pop_val;
print( (( $x )? "not ok ": "ok "), "2\n" ); # careful, reversed.

# Let the C side make a new entry.
$x = $a->push_val( 'Side' );
$x = $a->pop_val;
print( (($x eq 'Side')? "ok ": "not ok "), "3\n" );

######################################################################
# Now work with the subclass.

{ # Check scope
	sub CookBookA::Ex4C::DESTROY { print "ok 4\n" }
	@CookBookA::Ex4C::ISA = 'CookBookA::Ex4A';
	my $b = CookBookA::Ex4C->new;
}
print "ok 5\n";
$b = CookBookA::Ex4A->new;

# Show that the C code can read a array entry.
$b->[0] = 'Amos';
$x = $b->pop_val;
print( (($x eq 'Amos')? "ok ": "not ok "), "6\n" );

# Let the C side make a new entry.
$x = $b->push_val( 'County' );
$x = $b->pop_val;
print( (($x eq 'County')? "ok ": "not ok "), "7\n" );

######################################################################
# Let's do some unblessed stuff.

my $c = CookBookA::Ex4B::newarray();

# Show that the C code can read a array entry.
$c->[0] = 'Moe';
$x = CookBookA::Ex4B::get_val( $c );
print( (($x eq 'Moe')? "ok ": "not ok "), "8\n" );

# Show that Ex4B will take a blessed object, too.
# Show that the C code can read a array entry.
push @$b, 'Amos';
$x = CookBookA::Ex4B::get_val( $b );
print( (($x eq 'Amos')? "ok ": "not ok "), "9\n" );

# Show that Ex4B is looking for arrays.
{
	local $SIG{'__WARN__'} = sub { print "ok 10\n" };
	$x = CookBookA::Ex4B::get_val( {} );
	print( (( $x )? "not ok ": "ok "), "11\n" ); # careful, reversed.
}

