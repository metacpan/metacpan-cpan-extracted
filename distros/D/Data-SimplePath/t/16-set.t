#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 102);
}

my ($h, $root);
my $sub = sub {};

$h = Data::SimplePath -> new ();
is (scalar $h -> data (), undef, 'Root is undefined');

foreach ('abc', sub {}, qr/.*/, \('abc')) {
	is ($h -> set ('', $_), undef, "Invalid value for root: $_");
	is (scalar $h -> data (), undef, 'Root is still undefined');
}

# some simple tests with an empty root before the complex tests start:
$h = Data::SimplePath -> new ();
ok ($h -> set ('1/a/b', 'c'), 'Empyt set to some array stuff');
is_deeply ( scalar $h -> data (), [ undef, { 'a' => { 'b' => 'c' } } ], 'Matches #1' );

# same, auto_array off:
$h = Data::SimplePath -> new (undef, {'AUTO_ARRAY' => 0});
ok ($h -> set ('1/a/b', 'c'), 'Empyt set to some hash stuff');
is_deeply ( scalar $h -> data (), { '1' => { 'a' => { 'b' => 'c' } } }, 'Matches #2' );

# basically the same, auto_array on, no numeric keys:
$h = Data::SimplePath -> new ();
ok ($h -> set ('z/a/b', 'c'), 'Empyt set to some hash stuff again');
is_deeply ( scalar $h -> data (), { 'z' => { 'a' => { 'b' => 'c' } } }, 'Matches #3' );

# set the root to an empty hashref:
$h = Data::SimplePath -> new ();
ok ($h -> set ('', {}), 'Root set to empty hashref');
is_deeply (scalar $h -> data (), {}, 'Root is empty hashref');
$root = $h -> data ();

my @h_tests = (

# we start with the empty hashref and add the following data in the specified order:
# key			# value			# expected

[ 'a',		'B',	{ 'a' => 'B' }										],
[ 'a',		'A',	{ 'a' => 'A' }										],
[ 'a/1/b',	'*',	{ 'a' => [ undef, { 'b' => '*' } ] }							],

'AUTO_ARRAY_OFF', # special element => turn auto array off

[ 'b/0/1',	'B01',	{ 'a' => [ undef, { 'b' => '*' } ], 'b' => { '0' => { '1' => 'B01' } } }		],

'AUTO_ARRAY_ON', # special element => turn auto array on

[ 'b/1',	'B1',	{ 'a' => [ undef, { 'b' => '*' } ], 'b' => { '0' => { '1' => 'B01' }, '1' => 'B1' } }	],

[ ['a'],	{},	{ 'a' => {}, 'b' => { '0' => { '1' => 'B01' }, '1' => 'B1' } }				],
[ ['b'],	[],	{ 'a' => {}, 'b' => [] }								],

'ARRAY_WARNING_ON', # special element => following data will cause warnings!

[ ['b', 'c'],	'C',	{ 'a' => {}, 'b' => [] }								],
[ 'b/c/1/2/3',	'BC',	{ 'a' => {}, 'b' => [] }								],

'ARRAY_WARNING_OFF', # following stuff is valid again:

[ ['b',0,'a'],	'B0A',	{ 'a' => {}, 'b' => [ { 'a' => 'B0A' } ] }						],

'REPLACE_LEAF_OFF', # turn replace_leaf off
'LEAF_WARNING_ON', # following data will cause warnings:

[ 'b/0/a/0',	'BX',	{ 'a' => {}, 'b' => [ { 'a' => 'B0A' } ] }						],
[ 'b/0/a/0/c',	'BX',	{ 'a' => {}, 'b' => [ { 'a' => 'B0A' } ] }						],

'LEAF_WARNING_OFF',

[ 'b/0/a',	[],	{ 'a' => {}, 'b' => [ { 'a' => [] } ] }							],
[ 'b/0/a/0',	'BX',	{ 'a' => {}, 'b' => [ { 'a' => [ 'BX' ] } ] }						],
[ 'b/0/a',	'B0A',	{ 'a' => {}, 'b' => [ { 'a' => 'B0A' } ] }						],

'REPLACE_LEAF_ON', # turn replace_leaf on again
'LEAF_WARNING_OFF', # no more warnings

[ 'b/0/a/0',	'BX',	{ 'a' => {}, 'b' => [ { 'a' => [ 'BX' ] } ] }						],
[ 'b/0/a/0/c',	'BY',	{ 'a' => {}, 'b' => [ { 'a' => [ { 'c' => 'BY' } ] } ] }				],

'ERROR_ON', # general error, disables checking the key for undef, setting the key must return false:

[ '',		'X',	{ 'a' => {}, 'b' => [ { 'a' => [ { 'c' => 'BY' } ] } ] }				],

'ERROR_OFF',

[ 'b/0/a',	{},	{ 'a' => {}, 'b' => [ { 'a' => {} } ] }							],
[ 'b/0/1/1/0',	'3',	{ 'a' => {}, 'b' => [ { 'a' => {}, '1' => [ undef, [ '3' ] ] } ] }			],
[ 'b',		[],	{ 'a' => {}, 'b' => [] }								],

'AUTO_ARRAY_OFF',

[ 'b/0/1/1/0',	'XYZ',	{ 'a' => {}, 'b' => [ { '1' => { '1' => { '0' => 'XYZ' } } } ] }			],

);

my ($warn_array, $warn_leaf, $error) = (0, 0, 0);

foreach my $test (@h_tests) {

	if (ref $test eq 'ARRAY' and $warn_array == 0 and $warn_leaf == 0 and $error == 0) {
		ok ($h -> set ($test -> [0], $test -> [1]), "Set $test->[0]");
		is ($h -> get ($test -> [0]), $test -> [1], "Check $test->[0]");
		is_deeply ($root, $test -> [2], "Deep check $test->[0]");
	}
	elsif (ref $test eq 'ARRAY' and $warn_array == 1) {
		warning_like
			{ ok (! $h -> set ($test -> [0], $test -> [1]), "Set $test->[0]"); }
			qr/Trying to access array element with non-numeric key .+/,
			"Array warning for $test->[0] (set) ok";
		warning_like
			{ is ($h -> get ($test -> [0]), undef, "Check $test->[0]"); }
			qr/Trying to access array element with non-numeric key .+/,
			"Array warning for $test->[0] (check) ok";
		no warnings 'Data::SimplePath';
		ok (! $h -> set ($test -> [0], $test -> [1]), "Set $test->[0]");
		is ($h -> get ($test -> [0]), undef, "Check $test->[0]");
		use warnings;
		is_deeply ($root, $test -> [2], "Deep check $test->[0]");
	}
	elsif (ref $test eq 'ARRAY' and $warn_leaf == 1) {
		warning_like
			{ ok (! $h -> set ($test -> [0], $test -> [1]), "Set $test->[0]"); }
			qr/Trying to add an element beneath a scalar value/,
			"Leaf warning for $test->[0] (set) ok";
		is ($h -> get ($test -> [0]), undef, "Check $test->[0]");
		no warnings 'Data::SimplePath';
		ok (! $h -> set ($test -> [0], $test -> [1]), "Set $test->[0]");
		is ($h -> get ($test -> [0]), undef, "Check $test->[0]");
		use warnings;
		is_deeply ($root, $test -> [2], "Deep check $test->[0]");
	}
	elsif (ref $test eq 'ARRAY' and $error = 1) {
		ok (! $h -> set ($test -> [0], $test -> [1]), "Set $test->[0]");
		is_deeply ($root, $test -> [2], "Deep check $test->[0]");
	}
	elsif ($test eq 'AUTO_ARRAY_OFF') {
		$h -> auto_array (0);
		is ($h -> auto_array (), 0, 'AUTO_ARRAY is 0');
	}
	elsif ($test eq 'AUTO_ARRAY_ON') {
		$h -> auto_array (1);
		is ($h -> auto_array (), 1, 'AUTO_ARRAY is 1');
	}
	elsif ($test eq 'REPLACE_LEAF_OFF') {
		$h -> replace_leaf (0);
		is ($h -> replace_leaf (), 0, 'REPLACE_LEAF is 0');
	}
	elsif ($test eq 'REPLACE_LEAF_ON') {
		$h -> replace_leaf (1);
		is ($h -> replace_leaf (), 1, 'REPLACE_LEAF is 1');
	}
	elsif ($test eq 'ARRAY_WARNING_ON' ) { $warn_array = 1; }
	elsif ($test eq 'ARRAY_WARNING_OFF') { $warn_array = 0; }
	elsif ($test eq 'LEAF_WARNING_ON'  ) { $warn_leaf  = 1; }
	elsif ($test eq 'LEAF_WARNING_OFF' ) { $warn_leaf  = 0; }
	elsif ($test eq 'ERROR_ON'         ) { $error      = 1; }
	elsif ($test eq 'ERROR_OFF'        ) { $error      = 0; }

}

