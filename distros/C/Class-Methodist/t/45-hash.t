## -*- perl -*-

################ TestClass ################
package TestClass;

use Class::Methodist
  (
   ctor => 'new',
   hash => 'dictionary'
  );

################ main ################
package main;

use Test::More tests => 24;

my $tc = TestClass->new();

can_ok($tc, 'dictionary');
can_ok($tc, 'dictionary_exists');
can_ok($tc, 'dictionary_keys');
can_ok($tc, 'dictionary_values');

ok(! $tc->dictionary_exists('fred'), 'Non-existent/bang');

$tc->dictionary(fred => 'zelda');
is($tc->dictionary('fred'), 'zelda', 'Fred and Zelda');
$tc->dictionary(lives => 'peru');
is($tc->dictionary('lives'), 'peru', 'Is Peru');
isnt($tc->dictionary('lives'), 'zelda', 'Not Zelda');

my @keys = $tc->dictionary_keys();
ok(eq_set([ qw/fred lives/ ], \@keys), 'Keys');

my @vals = $tc->dictionary_values();
ok(eq_set([ qw/peru zelda/ ], \@vals), 'Values');

ok($tc->dictionary_exists('fred'), 'Fred exists');
ok($tc->dictionary_exists('lives'), 'Fred lives');

$tc->dictionary(alpha => 'beta', gamma => 'delta');
ok($tc->dictionary_exists('alpha'), 'Alpha exists');
ok($tc->dictionary_exists('gamma'), 'Gamma exists');
is($tc->dictionary('gamma'), 'delta', 'Gamma / delta');

is($tc->dictionary_size(), 4, 'Non-empty');
$tc->dictionary_clear();
@keys = $tc->dictionary_keys();
is(0, scalar @keys, 'No keys');
@vals = $tc->dictionary_values();
is(0, scalar @vals, 'No values');
is($tc->dictionary_size(), 0, 'Empty');

## Increment
my $tc2 = TestClass->new();
$tc2->dictionary_inc('alpha');
is($tc2->dictionary('alpha'), 1, 'Autovivify');

$tc2->dictionary(beta => 1);
is($tc2->dictionary('beta'), 1, 'Set');
$tc2->dictionary_inc('beta');
$tc2->dictionary_inc('beta');
is($tc2->dictionary('beta'), 3, 'Set');

## Attributes as string.
$tc2->dictionary_clear();
$tc2->dictionary(fred => 'lives', with => 'zelda', in => 'peru');
my $as_string = $tc2->attributes_as_string(qw/dictionary/);
$as_string =~ s/\e.*?m//g;	# Strip off ANSI codes, if any
is($as_string, '(TestClass dictionary={fred=lives,in=peru,with=zelda})',
   'Attribute as string OK');

## Initialize with reference to hash.
$tc2->dictionary_clear();
$tc2->dictionary( { zelda => 'lives',
		    with => 'fred' } );
$as_string = $tc2->attributes_as_string(qw/dictionary/);
$as_string =~ s/\e.*?m//g;	# Strip off ANSI codes, if any
is($as_string, '(TestClass dictionary={with=fred,zelda=lives})',
   'Second Attribute as string OK');
