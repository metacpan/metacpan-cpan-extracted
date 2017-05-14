## -*- perl -*-

################ TestClass ################
package TestClass;

use Class::Methodist
  (
   ctor => 'new',
   list => 'things'
  );

################ main ################
package main;

use Test::More tests => 67;

can_ok('TestClass', 'new');
my $tc1 = TestClass->new();
isa_ok($tc1, 'TestClass');
can_ok($tc1, 'things');

my @expected = (2, 4, 6, 10);
$tc1->things(@expected);

my @actual = $tc1->things();
ok(eq_array(\@expected, \@actual), 'Array context');

my $actual = $tc1->things();
ok(eq_array(\@expected, $actual), 'Scalar context');

push @expected, 'fred';
my $count = $tc1->push_things('fred');
is($count, 5, 'Count after push');
$actual = $tc1->things();
ok(eq_array(\@expected, $actual), 'After push');

pop @expected;
my $val = $tc1->pop_things();
is($val, 'fred', 'Val of pop');
$actual = $tc1->things();
ok(eq_array(\@expected, $actual), 'After pop');

is($tc1->count_things(), 4, "Count before pop");
$tc1->pop_things();
is($tc1->count_things(), 3, "Count after pop");

is($tc1->shift_things(), 2, 'Shift');
is($tc1->count_things(), 2, 'Count after shift');

$tc1->unshift_things(44, 45, 46);
is($tc1->count_things(), 5, 'Count after unshift');
is($tc1->shift_things(), 44, 'Shift after unshift');

my @more_expected = qw/alpha beta gamma delta/;
$tc1->things(@more_expected);
my @more_actual = $tc1->things();
ok(eq_array(\@more_expected, \@more_actual), 'Set as array');

$tc1->things(\@more_expected);
@more_actual = $tc1->things();
ok(eq_array(\@more_expected, \@more_actual), 'Set as array reference');

# Grep
$tc1->things(qw/alpha beta gamma delta/);

@actual = $tc1->grep_things(qr/alpha/);
ok(eq_set(\@actual, [ 'alpha' ]), 'First element of list');

@actual = $tc1->grep_things(qr/beta/);
ok(eq_set(\@actual, [ 'beta' ]), 'Interior element of list');

@actual = $tc1->grep_things(qr/delta/);
ok(eq_set(\@actual, [ 'delta' ]), 'Last element of list');

@actual = $tc1->grep_things(qr/^[ab]/);
ok(eq_set(\@actual, [ 'alpha', 'beta' ]), 'Two elts (char class)');

@actual = $tc1->grep_things(qr/^[^ab]/);
ok(eq_set(\@actual, [ 'gamma', 'delta' ]), 'Two elts (negated char class)');

# Clear
$tc1->things(qw/a b c/);
is($tc1->count_things(), 3, 'Properly initialized');

$tc1->things();
is($tc1->count_things(), 3, 'Not changed by query');

$tc1->clear_things();
is($tc1->count_things(), 0, 'Clears properly');

# Join
$tc1->clear_things();
is($tc1->join_things(), '', 'Empty list');

$tc1->things('alpha');
is($tc1->join_things(), 'alpha', 'Single element, empty glue');
is($tc1->join_things('XX'), 'alpha', 'Single element, non-empty glue');

$tc1->things(qw/alpha beta/);
is($tc1->join_things(), 'alphabeta', 'Pair, empty glue');
is($tc1->join_things(''), 'alphabeta', 'Pair, glue same as default');
is($tc1->join_things(' '), 'alpha beta', 'Pair, single whitespace glue');
is($tc1->join_things('XX'), 'alphaXXbeta', 'Pair, non-trivial glue');

$tc1->things(qw/alpha beta gamma delta/);
is($tc1->join_things(), 'alphabetagammadelta', 'Longer list, empty glue');
is($tc1->join_things(''), 'alphabetagammadelta',
   'Longer list, glue same as default');
is($tc1->join_things(' '), 'alpha beta gamma delta',
   'Longer list, single whitespace glue');
is($tc1->join_things('XX'), 'alphaXXbetaXXgammaXXdelta',
   'Longer list, non-trivial glue');

# First
$tc1->clear_things();
is($tc1->first_of_things(), undef, 'Empty first undefined');
$tc1->things('alpha');
is($tc1->first_of_things(), 'alpha', 'Single-element list first OK');
$tc1->things('alpha', 'beta', 'gamma');
is($tc1->first_of_things(), 'alpha', 'Multi-element list first OK');

# Last
$tc1->clear_things();
is($tc1->last_of_things(), undef, 'Empty last undefined');
$tc1->things('alpha');
is($tc1->last_of_things(), 'alpha', 'Single-element list last OK');
$tc1->things('alpha', 'beta', 'gamma');
is($tc1->last_of_things(), 'gamma', 'Multi-element list last OK');

# Attributes as string
$tc1->things(qw/alpha beta gamma/);
my $as_string = $tc1->attributes_as_string(qw/things/);
$as_string =~ s/\e.*?m//g;	# Strip off ANSI codes, if any
is($as_string, '(TestClass things=[alpha,beta,gamma])',
   'Attributes as string OK');

# Push if new
$tc1->clear_things();
is($tc1->count_things, 0, 'Clears properly');
is($tc1->push_things_if_new('alpha'), 1, 'Push alpha');
ok(eq_array([ 'alpha' ], [ $tc1->things() ]), 'New on empty list');

is($tc1->push_things_if_new('alpha'), 1, 'Re-push alpha');
ok(eq_array([ 'alpha' ], [ $tc1->things() ]), 'Same as singleton list');

is($tc1->push_things_if_new('beta'), 2, 'Push beta');
ok(eq_array([ 'alpha', 'beta' ], [ $tc1->things() ]), 'Push new on sigleton');

is($tc1->push_things_if_new('beta'), 2, 'Re-push beta');
ok(eq_array([ 'alpha', 'beta' ], [ $tc1->things() ]), 'Re-push beta');

is($tc1->push_things_if_new('alpha'), 2, 'Re-push alpha');
ok(eq_array([ 'alpha', 'beta' ], [ $tc1->things() ]), 'Re-push alpha');

is($tc1->push_things_if_new('gamma'), 3, 'Push gamma');
ok(eq_array([ 'alpha', 'beta', 'gamma' ], [ $tc1->things() ]), 'Push gamma');

is($tc1->shift_things(), 'alpha', 'Shift off alpha');
is($tc1->count_things(), 2, 'Count correct after shift');

is($tc1->push_things_if_new('beta'), 2, 'Re-push beta');
ok(eq_array([ 'beta', 'gamma' ], [ $tc1->things() ]), 'Re-push beta');

is($tc1->push_things_if_new('alpha'), 3, 'Push alpha');
ok(eq_array([ 'beta', 'gamma', 'alpha' ], [ $tc1->things() ]), 'Push alpha');

is($tc1->push_things_if_new(qw/delta epsilon/), 5, 'Push delta, epsilon');
ok(eq_array([ qw/beta gamma alpha delta epsilon/ ],
	    [ $tc1->things() ]), 'Push delta, epsilon');

# Empty stuff
$tc1 = TestClass->new();
is($tc1->join_things(), '', 'Empty join');

$tc1 = TestClass->new();
is($tc1->pop_things(), undef, 'Empty pop');

$tc1 = TestClass->new();
is($tc1->shift_things(), undef, 'Empty shift');
