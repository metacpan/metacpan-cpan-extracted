#!/usr/bin/env perl

use strict;
use warnings;

use Set::Array;
use Set::Scalar;
use Set::Tiny;

# -----------------

my($a1) = Set::Array -> new(qw(a b c d e) );
my($a2) = Set::Array -> new(qw(    c d e f g) );
my($a3) = Set::Array -> new(qw(        e f g h i) );
my($a4) = Set::Array -> new(@$a2, @$a3);
my($s1) = Set::Scalar -> new(qw(a b c d e) );
my($s2) = Set::Scalar -> new(qw(    c d e f g) );
my($s3) = Set::Scalar -> new(qw(        e f g h i) );
my($t1) = Set::Tiny -> new(qw(a b c d e) );
my($t2) = Set::Tiny -> new(qw(    c d e f g) );
my($t3) = Set::Tiny -> new(qw(        e f g h i) );
my($t4) = Set::Tiny -> new($t2 -> members, $t3 -> members);

print 'Set::Array.symmetric_difference:  ', join(' ', sort $a1 -> symmetric_difference($a4) ), "\n";
print 'Set::Scalar.symmetric_difference: ', $s1 -> symmetric_difference($s2, $s3), "\n";
print 'Set::Tiny.symmetric_difference:   ', join(' ', sort $t1 -> symmetric_difference($t4) -> members), "\n";
print "Now test if Set::Array updates the invocant: \n";
print "Before: ", join(' ', sort $a1 -> print), "\n";
my $difference = $a1 -> difference($a2); # Overload $a1 - $a2 has the same effect.
print "After:  ", join(' ', sort $a1 -> print), "\n";

__END__
Output:
Set::Array.symmetric_difference:  a b f g h i
Set::Scalar.symmetric_difference: (a b e h i)
Set::Tiny.symmetric_difference:   a b f g h i
Now test if Set::Array updates the invocant:
Before: a b c d e
After:  a b
