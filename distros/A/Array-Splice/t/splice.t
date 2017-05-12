#!./perl

# Copied from perl-5.9.5/t/op/splice.t

use Array::Splice qw ( splice_aliases );

print "1..18\n";

@a = (1..10);

sub j { join(":",@_) }

print "not " unless j(splice_aliases(@a,@a,0,11,12)) eq "" && j(@a) eq j(1..12);
print "ok 1\n";

# Two and three argument forms not supported by splice_aliases
print "not " unless j(splice(@a,-1)) eq "12" && j(@a) eq j(1..11);
print "ok 2\n";

print "not " unless j(splice(@a,0,1)) eq "1" && j(@a) eq j(2..11);
print "ok 3\n";

print "not " unless j(splice_aliases(@a,0,0,0,1)) eq "" && j(@a) eq j(0..11);
print "ok 4\n";

print "not " unless j(splice_aliases(@a,5,1,5)) eq "5" && j(@a) eq j(0..11);
print "ok 5\n";

print "not " unless j(splice_aliases(@a, @a, 0, 12, 13)) eq "" && j(@a) eq j(0..13);
print "ok 6\n";

print "not " unless j(splice_aliases(@a, -@a, @a, 1, 2, 3)) eq j(0..13) && j(@a) eq j(1..3);
print "ok 7\n";

print "not " unless j(splice_aliases(@a, 1, -1, 7, 7)) eq "2" && j(@a) eq j(1,7,7,3);
print "ok 8\n";

print "not " unless j(splice_aliases(@a,-3,-2,2)) eq j(7) && j(@a) eq j(1,2,7,3);
print "ok 9\n";

# Bug 20000223.001 - no test for splice_aliases(@array).  Destructive test!
print "not " unless j(splice(@a)) eq j(1,2,7,3) && j(@a) eq '';
print "ok 10\n";

my $foo;

@a = ('red', 'green', 'blue');
$foo = splice_aliases @a, 1, 2;
print "not " unless $foo eq 'blue';
print "ok 11\n";

@a = ('red', 'green', 'blue');
$foo = shift @a;
print "not " unless $foo eq 'red';
print "ok 12\n";

# Bug [perl #30568] - insertions of deleted elements
@a = (1, 2, 3);
splice_aliases( @a, 0, 3, $a[1], $a[0] );
print "not " unless j(@a) eq j(2,1);
print "ok 13\n";

@a = (1, 2, 3);
splice_aliases( @a, 0, 3 ,$a[0], $a[1] );
print "not " unless j(@a) eq j(1,2);
print "ok 14\n";

@a = (1, 2, 3);
splice_aliases( @a, 0, 3 ,$a[2], $a[1], $a[0] );
print "not " unless j(@a) eq j(3,2,1);
print "ok 15\n";

@a = (1, 2, 3);
splice_aliases( @a, 0, 3, $a[0], $a[1], $a[2], $a[0], $a[1], $a[2] );
print "not " unless j(@a) eq j(1,2,3,1,2,3);
print "ok 16\n";

@a = (1, 2, 3);
splice_aliases( @a, 1, 2, $a[2], $a[1] );
print "not " unless j(@a) eq j(1,3,2);
print "ok 17\n";

@a = (1, 2, 3);
splice_aliases( @a, 1, 2, $a[1], $a[1] );
print "not " unless j(@a) eq j(1,2,2);
print "ok 18\n";
