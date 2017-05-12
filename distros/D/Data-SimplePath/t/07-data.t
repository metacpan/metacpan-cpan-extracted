#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 16);
}

my ($h, $d, $r, %h, @a);

$h = Data::SimplePath -> new ();

# no data defined yet, data () must return undef or empty lists:
$r = $h -> data ();
is ($r, undef, 'No ref returned');
%h = $h -> data ();
is_deeply (\%h, {}, 'Empty hash');
@a = $h -> data ();
is_deeply (\@a, [], 'Empty array');

# use an object with a hashref as root:
$d = {'a' => 'b', 'c' => 'd'};
$h = Data::SimplePath -> new ($d);
$r = $h -> data ();
is ($r, $d, 'Same reference');
is (ref $r, 'HASH', 'Ref is hash');
# this must change the data in the object:
$r -> {'a'} = 'abc';
is_deeply ($d, { 'a' => 'abc', 'c' => 'd' }, 'Same structure');

# something deeper:
$d = ['a', {'b' => 'c'}];
$h = Data::SimplePath -> new ($d);
$r = $h -> data ();
is ($r, $d, 'Same reference #2');
is (ref $r, 'ARRAY', 'Ref is array');
$r -> [1] {'b'} = 'abc';
is_deeply ($d, ['a', {'b' => 'abc'}], 'Same structure');

# now some tests with data copies:
$d = {'a' => {'b' => 'c'}};
$h = Data::SimplePath -> new ($d);
%h = $h -> data ();
isnt (\%h, $d);
is_deeply (\%h, {'a' => {'b' => 'c'}});
$h {'a'} -> {'b'} = 'x';
is_deeply ($d, {'a' => {'b' => 'c'}}, 'Original structure');

# same with an array as root:
$d = ['a', {'b' => 'c'}, 'd'];
$h = Data::SimplePath -> new ($d);
@a = $h -> data ();
isnt (\@a, $d);
is_deeply (\@a, ['a', {'b' => 'c'}, 'd']);
$a [1] -> {'b'} = 'x';
is_deeply ($d, ['a', {'b' => 'c'}, 'd'], 'Original structure');
