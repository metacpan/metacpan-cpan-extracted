#!perl -w

print "1..9\n";

use CookBookA::Ex2 qw( :DEFAULT );

my $x;

# First, demonstrate the basics.

# show that we can share the variable which is living on the C side
$x = ex2_debug_c();
print( (($x == 42)? "ok ": "not ok "), "1\n" );
ex2_debug_c( 10 );
$x = ex2_debug_c();
print( (($x == 10)? "ok ": "not ok "), "2\n" );

# show that we can share the variable which is living on the Perl side
print( (($ex2_debug_p == 77)? "ok ": "not ok "), "3\n" );
$x = ex2_debug_p();
print( (($x == 77)? "ok ": "not ok "), "4\n" );
ex2_debug_p( 42 );
$x = ex2_debug_p();
print( (($x == 42)? "ok ": "not ok "), "5\n" );


# Now demonstrate the tie() to share a variable living on the C side.

print( (($ex2_debug_c == 10)? "ok ": "not ok "), "6\n" );
$ex2_debug_c = 3;
print( (($ex2_debug_c == 3)? "ok ": "not ok "), "7\n" );
$x = ex2_debug_c();
print( (($x == 3)? "ok ": "not ok "), "8\n" );
ex2_debug_c( 11 );
print( (($ex2_debug_c == 11)? "ok ": "not ok "), "9\n" );
