#!perl -w

print "1..11\n";

use strict;
require CookBookA::Ex3;


my $a;
my $b;
my $x;

######################################################################
# First, work with the base class.

$a = CookBookA::Ex3->new;

# Show that the C code can read a hash entry.
$a->{Left} = 'Right';
$x = $a->say_key( 'Left' );
print( (($x eq 'Right')? "ok ": "not ok "), "1\n" );

# What happens when the entry doesn't exist?
$x = $a->say_key( 'Up' );
print( (( $x )? "not ok ": "ok "), "2\n" ); # careful, reversed.

# Let the C side make a new entry.
$x = $a->put_key( 'Far', 'Side' );
$x = $a->say_key( 'Far' );
print( (($x eq 'Side')? "ok ": "not ok "), "3\n" );

######################################################################
# Now work with the subclass.

{ # Check scope
	no strict 'vars';
	package CookBookA::Ex3C;
	sub DESTROY { print "ok 4\n" }
	@ISA = 'CookBookA::Ex3A';
	my $b = CookBookA::Ex3C->new;
}
print "ok 5\n";
my $b = CookBookA::Ex3A->new;

# Show that the C code can read a hash entry.
$b->{Andy} = 'Amos';
$x = $b->say_key( 'Andy' );
print( (($x eq 'Amos')? "ok ": "not ok "), "6\n" );

# Let the C side make a new entry.
$x = $b->put_key( 'Bloom', 'County' );
$x = $b->say_key( 'Bloom' );
print( (($x eq 'County')? "ok ": "not ok "), "7\n" );

######################################################################
# Let's do some unblessed stuff.

my $c = CookBookA::Ex3B::newhash();

# Show that the C code can read a hash entry.
$c->{Curly} = 'Moe';
$x = CookBookA::Ex3B::getkey( $c, 'Curly' );
print( (($x eq 'Moe')? "ok ": "not ok "), "8\n" );

# Show that Ex3B will take a blessed object, too.
# Show that the C code can read a hash entry.
$b->{Andy} = 'Amos';
$x = CookBookA::Ex3B::getkey( $b, 'Andy' );
print( (($x eq 'Amos')? "ok ": "not ok "), "9\n" );

# Show that Ex3B is looking for hashes.
{
	local $SIG{'__WARN__'} = sub { print "ok 10\n" };
	$x = CookBookA::Ex3B::getkey( [], 'Andy' );
	print( (( $x )? "not ok ": "ok "), "11\n" ); # careful, reversed.
}

