#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 26);
}

my ($d, $h1, $h2);

# create a new object (with default options) and clone it:
$d = { 'a' => 'b', 'c' => {'d' => 'e'}, 'f' => ['g', 'h'] };
$h1 = Data::SimplePath -> new ($d);
$h2 = $h1 -> clone ();

# must be a Data::SimplePath object:
isa_ok ($h2, 'Data::SimplePath');

# but not the same, and with a different data ref:
isnt ($h1, $h2, 'Different objects');
isnt (scalar $h1 -> data (), scalar $h2 -> data (), 'Different root refs');
is (scalar $h1 -> data (), $d, '$h1 data still ok');

# but the data in the objects itself must be identical:
is_deeply ($h1, $h2, 'Both are identical');

# change something and check the objects' data:
$d -> {'c'} {'d'} = 'X';
is_deeply (
	scalar $h1 -> data (),
	{ 'a' => 'b', 'c' => {'d' => 'X'}, 'f' => ['g', 'h'] },
	'$h1 changed'
);
is_deeply (
	scalar $h2 -> data (),
	{ 'a' => 'b', 'c' => {'d' => 'e'}, 'f' => ['g', 'h'] },
	'$h2 still unchanged'
);

# change some options and check the objects:
$h1 -> auto_array   (  0);
$h1 -> replace_leaf (  0);
$h2 -> separator    (':');

is ( $h1 -> auto_array   (),   0, '$h1 AUTO_ARRAY is 0'   );
is ( $h2 -> auto_array   (),   1, '$h2 AUTO_ARRAY is 1'   );
is ( $h1 -> replace_leaf (),   0, '$h1 REPLACE_LEAF is 2' );
is ( $h2 -> replace_leaf (),   1, '$h2 REPLACE_LEAF is 1' );
is ( $h1 -> separator    (), '/', '$h1 SEPARATOR is /'    );
is ( $h2 -> separator    (), ':', '$h2 SEPARATOR is :'    );

# now create an object without any data, and non-default settings and clone it:
$h1 = Data::SimplePath -> new (
	undef,
	{ 'AUTO_ARRAY' => 0, 'REPLACE_LEAF' => 0, 'SEPARATOR' => '#' }
);
$h2 = $h1 -> clone ();

# basically the same tests as above:
isa_ok ($h2, 'Data::SimplePath');

isnt ($h1, $h2);

is ($h1 -> data (), undef, '$h1 data undef');
is ($h2 -> data (), undef, '$h2 data undef');

is ( $h1 -> auto_array   (),   0, '$h1 AUTO_ARRAY is 0'   );
is ( $h2 -> auto_array   (),   0, '$h2 AUTO_ARRAY is 0'   );
is ( $h1 -> replace_leaf (),   0, '$h1 REPLACE_LEAF is 0' );
is ( $h2 -> replace_leaf (),   0, '$h2 REPLACE_LEAF is 0' );
is ( $h1 -> separator    (), '#', '$h1 SEPARATOR is #'    );
is ( $h2 -> separator    (), '#', '$h2 SEPARATOR is #'    );

$h1 -> set ('a#0#b', 'c');

is_deeply (scalar $h1 -> data (), {'a' => {'0' => {'b' => 'c'}}}, '$h1 data set');
is ($h2 -> data (), undef, '$h2 still undef');

# a better way to check this stuff is checking the actual reference count of the elements with the
# SvREFCNT function of Devel::Peek. maybe later...
