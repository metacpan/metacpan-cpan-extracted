
# For testing the regular array behaviour of the module.
# Except that this version does NOT allow undef values in the array
# so if you put a value at an index which would leave undefs in
# between the new value is appended to the end of the array

# The tests in this file should include only unique values so they 
# whould work even with a regular array (except of the undefs).

# TODO:
# this returns strange, (undefined ?) value

use strict;
use warnings;
use Test::More;
#my @modes = (undef, 'Std', 'IxHash');
#my @modes = ('Hash');

#my @modes = ('default', 'standard'); 
my @modes = ('default', 'standard', 'unique'); 

# default = what we have in Perl
# standard  = using Array::Std, 
# unique = Array::Unique

plan tests => (50 * @modes);
#plan tests => (47);


foreach my $m (@modes) {
    unit_test($m);
}
exit;

#######################################################

sub unit_test {
   my $mode = shift;


my @a;
my $o;
my @c;


SKIP: {
      skip 'needed for unique only', 3 unless $mode eq 'unique';
      eval { require Array::Unique; };

      is($@, '', 'Load module Array::Unique');
      die $@ if $@;

      eval {$o = tie @a, 'Array::Unique';};
      is($@, '', 'tie-ing an array');
      die $@ if $@;
      is(ref $o, 'Array::Unique', 'received Array::Unique object');
}

SKIP: {
      skip 'needed for default only', 1 unless $mode eq 'standard';
      require Tie::Array;
      $o = tie @a, 'Tie::StdArray';
      is(ref $o, 'Tie::StdArray', 'received a Tie::StdArray object');
}

# ---------------------------------------------------
# create a simple array
# ---------------------------------------------------
@c=@a=qw(a b c d);
is(@a, 4, 'length is really 5');
is_deeply(\@a, [qw(a b c d)], 'Create an array with simple assignement of 4 elements');
is_deeply(\@c, [qw(a b c d)], 'create array returns the same array');


@c=@a=();
is(@a, 0, 'set empty array');
is(@c, 0, 'set empty array with returned value');


@a=qw(a b c d);

# ---------------------------------------------------
# fetch the value of a specific element in the array
# ---------------------------------------------------
is($a[0],  "a", 'fetch the value of element 0');
is($a[2],  "c", 'fetch the value of element 2');
is($a[-1], "d", 'fetch the value of element -1');
is($a[-2], "c", 'fetch the value of element -2');


# ---------------------------------------------------
# set a value in a specific index
# ---------------------------------------------------
$a[@a] = 'e';
is_deeply(\@a, [qw(a b c d e)], 
   'set a value at an index higher than size of array');

$a[1] = 'x';
is_deeply(\@a, [qw(a x c d e)], 'set value in an existing index');

$a[0] = 'z';
is_deeply(\@a, [qw(z x c d e)], 'set value in an existing index (0)');

$a[-1] = "p";
is_deeply(\@a, [qw(z x c d p)], 'Set the value of negative indexes, -1');

$a[-2] = "y";
is_deeply(\@a, [qw(z x c y p)], 'Set the value of negative indexes -2');

$a[@a+2] = 'q';
# this is not even the normal behavior:

SKIP: {
      skip 'only the standard behavior', 2 unless $mode eq 'default' or
						  $mode eq 'standard';
      is(@a, 8, 'lenght includes undefs in the middle');
      is_deeply(\@a, ['z', 'x', 'c', 'y', 'p', undef, undef, 'q'],  'set value - with a break in the indexes');
}

SKIP: {
      skip 'behavior only in unique module', 2 unless $mode eq 'unique';
      is(@a, 6, 'lenght does not includ undefs in the middle as they are removed');
      is_deeply(\@a, ['z', 'x', 'c', 'y', 'p', 'q'],  'set value - with a break in the indexes');
}


# ---------------------------------------------------
# change the size of the array
# check the size
# ---------------------------------------------------
my $t = $#a = 3;
is($t, 3, 'set length returns the correct value');

is($#a, 3, 'length was set correctly');
is(@a, 4, 'number of elements is correct');
is_deeply(\@a, [qw(z x c y)], 'array shortened correctly');

$#a=0;
is_deeply(\@a, ['z'], 'set length of 0');


# ---------------------------------------------------
# push
# ---------------------------------------------------
@a = qw(a b c d e);
my $length = @a;
is_deeply([push(@a, 'f')], [$length+1], 'push one value on the array returns new size');
is_deeply(\@a, [qw(a b c d e f)], 'push successfull');
#print "DEBUG: '@a'\n";

is_deeply([push(@a, 'g', 'h')], [$length+3], 'push returns new length');
is_deeply(\@a, [qw(a b c d e f g h)], 'push successfull');


# ---------------------------------------------------
# pop
# ---------------------------------------------------
my $p = pop(@a);
is($p, "h", 'pop last element works');
is_deeply(\@a, [qw(a b c d e f g)], 'remaining array after pop is correct');


# ---------------------------------------------------
# shift
# ---------------------------------------------------
my $s = shift @a;
is($s, "a", 'shift first element works');
is_deeply(\@a, [qw(b c d e f g)], 'array is correct after shift');


# ---------------------------------------------------
# unshift
# ---------------------------------------------------
is_deeply([unshift @a, 'z'],[7] , 'unshift returns new length correctly');
is_deeply(\@a, [qw(z b c d e f g)], 'unshift works correctly with one value');




# ---------------------------------------------------
# splice
# ---------------------------------------------------
my @b = splice(@a, 2, 3);
is_deeply(\@b, [qw(c d e)], 'splice returns the cut out part');
is_deeply(\@a, [qw(z b f g)], 'splice leaves the correct array');

@b = splice(@a, 2, 1, qw(x y w));
is_deeply(\@b, [qw(f)], 'splice retursn the cut out part');
is_deeply(\@a, [qw(z b x y w g)], 'splice - replace was successfull');

# ---------------------------------------------------
# splice with negative values
# ---------------------------------------------------
@b = splice(@a, -1);
is_deeply(\@b, [qw(g)], 'cut out the last element with -1');
is_deeply(\@a, [qw(z b x y w)],'remaining all but the last element');

@a = qw(a b c d e f g h i j k);
@b = splice (@a, -5, 3, qw(z));
is_deeply(\@b, [qw(g h i)], 'cut out a few elements with negative index');
is_deeply(\@a, [qw(a b c d e f z j k)], 'inserted elements after cut out');

@b = splice(@a, 1, -1);
is_deeply(\@a, [qw(a k)], 'negative length');
is_deeply(\@b, [qw(b c d e f z j)], 'negative length');



@b = @a = (qw(a b c d), qw(x y z));
is_deeply(\@a, [qw(a b c d x y z)], 'pass value of just created array');
is_deeply(\@b, [qw(a b c d x y z)], 'pass value of just created array');

my $b = @a = (qw(a b c d), qw(x y z));
is($b, 7, 'pass scalar value of created array');

}



