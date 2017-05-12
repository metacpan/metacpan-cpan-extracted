#!perl -w

print "1..9\n";

use strict;
require CookBookA::Ex6;
#use ExtUtils::Peek 'Dump';

my $a;

sub Ex6A::DESTROY { print "ok 7\n" }
sub Ex6C::DESTROY { print "ok 9\n" }

{ # Check scope
	no strict 'vars';
	package CookBookA::Ex6B;
	sub DESTROY { print "ok 1\n"; CookBookA::Ex6::DESTROY(@_) }
	@ISA = 'CookBookA::Ex6';
	my $a = CookBookA::Ex6B->new;
}
print "ok 2\n";

$a = CookBookA::Ex6->new;

{
	# $x lives to the end of this block, but the object won't be
	# destroyed because the C object is holding a reference to it and
	# has incremented its refcount.
	my $x = bless [], 'Ex6A';
	$x->[0] = 'Right';

	# Store $x in the object.
	$a->saveit( $x );
}
print "ok 3\n";

{
	# $x lives to the end of this block, but the object won't be
	# destroyed because the C object is holding a reference to it and
	# has incremented its refcount.
	my $x = bless [], 'Ex6C';
	$x->[0] = 'Right';

	# Store $x in the object.
	$a->saveit2( $x );
}
print "ok 4\n";

# Get $x, but the C object still holds a reference so $x's destructor
# still won't be called.
{
	my $d = $a->getit;
	print( (($d->[0] eq 'Right')? "ok ": "not ok "), "5\n" );
}

# Get $x, but tell the C object to drop its own reference, to decrement
# the refcount.  This means we have the only reference to the object.
# When we go out of scope the object dies.
{
	my $c = $a->dropit;
	print( (($c->[0] eq 'Right')? "ok ": "not ok "), "6\n" );
}
print "ok 8\n";

# The object Ex6C will be destroyed after Perl calls the destructor for
# the container object.
