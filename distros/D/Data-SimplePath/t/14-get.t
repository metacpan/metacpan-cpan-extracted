#!/usr/bin/perl -T

# Note: There have been a few regexps in here (qr/.*/), but apparently Storage
# doesn't like these any more. I'm pretty sure it did work when I wrote the
# tests, but not any more. So the regexps have been wrapped in quotes for now.

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 225);
}

my $data = {
	'a'                     => {            # a
		'aa'            => {            # a/aa
			'aaa'   => 'AAA',       # a/aa/aaa
		},
		'ab'            => [            # a/ab
			'AB0',                  # a/ab/0
			'AB1',                  # a/ab/1
			'AB2'                   # a/ab/2
		],
		'ac'            => 'AC',        # a/ac
	},
	'b'                     => [            # b
		{                               # b/0
			'b0a'   => 'qr/.*/',    # b/0/b0a
		},
		[                               # b/1
			'B10',                  # b/1/0
			'B11',                  # b/1/1
			'B12'                   # b/1/2
		],
		'B2'                            # b/2
	],
	'c'                     => undef,       # c
};

my %expected = (
	'///'           => $data,
	'xyz'           => undef,
	'1'             => undef,
	'a'             => $data -> {'a'},
	'a/xy'          => undef,
	'a/aa'          => $data -> {'a'} {'aa'},
	'/a/aa/xyz/'    => undef,
	'a//aa//aaa'    => $data -> {'a'} {'aa'} {'aaa'},
	'a/aa/aaa/xyz'  => undef,
	'a/ab'          => $data -> {'a'} {'ab'},
	'//a//ab//0//'  => $data -> {'a'} {'ab'} [0],
	'a/ab/1'        => $data -> {'a'} {'ab'} [1],
	'a/ab/2'        => $data -> {'a'} {'ab'} [2],
	'a/ab/3'        => undef,
	'a/ac'          => $data -> {'a'} {'ac'},
	'a/ac/xyz'      => undef,
	'b'             => $data -> {'b'},
	'b/3'           => undef,
	'b/0'           => $data -> {'b'} [0],
	'b/0/xyz'       => undef,
	'b/0/1'         => undef,
	'b/0/b0a'       => $data -> {'b'} [0] {'b0a'},
	'b/1'           => $data -> {'b'} [1],
	'b/1/3'         => undef,
	'b/1/0'         => $data -> {'b'} [1] [0],
	'b/1/0/1'       => undef,
	'b/1/1'         => $data -> {'b'} [1] [1],
	'b/1/1/xyz'     => undef,
	'b/1/2'         => $data -> {'b'} [1] [2],
	'b/2'           => $data -> {'b'} [2],
	'b/2/xyz///'    => undef,
	'///c'          => $data -> {'c'},
);

my $h = Data::SimplePath -> new ($data);
my $e = Data::SimplePath -> new ();

is_deeply (scalar $h -> data (), $data, 'Structure ok after init');
is (scalar $e -> data (), undef, 'Empty object ok');

# simple check for some existing and non-existing elements, no warnings:
while (my ($k, $v) = each %expected) {
	is ($h -> get ($k), $v, "$k ok");
	is ($e -> get ($k), undef, 'Empty => undef');
	my @p = split '/', $h -> normalize_key ($k);
	is ($h -> get (\@p), $v, "$k split ok");
	is ($e -> get (\@p), undef, 'Empty => undef');
}

%expected = (
	'a/ab/xyz'      => undef,
	'b/xyz'         => undef,
	'b/1/xyz'       => undef,
	'b/1/xyz/abc/d'	=> undef,
);

# access to array elements with non-numeric keys must cause a warning:
while (my ($k, $v) = each %expected) {
	warning_like
		{ is ($h -> get ($k), $v, "$k ok") }
		qr/Trying to access array element with non-numeric key /,
		"Warning for key $k ok";
	is ($e -> get ($k), undef, 'Empty => undef');
	my @p = split '/', $h -> normalize_key ($k);
	warning_like
		{ is ($h -> get (\@p), $v, "$k split ok") }
		qr/Trying to access array element with non-numeric key /,
		"Warning for split key $k ok";
	is ($e -> get (\@p), undef, 'Empty => undef');
}

# unless warnings are disabled:
no warnings 'Data::SimplePath';
while (my ($k, $v) = each %expected) {
	is ($h -> get ($k), $v, "$k ok");
	is ($e -> get ($k), undef, 'Empty => undef');
	my @p = split '/', $h -> normalize_key ($k);
	is ($h -> get (\@p), $v, "$k split ok");
	is ($e -> get (\@p), undef, 'Empty => undef');
}
use warnings;

# in list context a copy must be returned:
my %a = $h -> get ('a');
is_deeply (\%a, $data -> {'a'}, '% ok');
isnt ($a {'aa'}, $data -> {'a'} {'aa'}, 'Ref %1 ok'); # references must not be the same!
isnt ($a {'ab'}, $data -> {'a'} {'ab'}, 'Ref %2 ok');

# same for an array instead of a hash:
my @b = $h -> get ('b');
is_deeply (\@b, $data -> {'b'}, '@ ok');
isnt ($b [0], $data -> {'b'} [0], 'Ref @1 ok');
isnt ($b [1], $data -> {'b'} [1], 'Ref @2 ok');

# with the empty key, it must return the same results as the data method:
is (scalar $h -> get (''), scalar $h -> data (), 'Data = Get');
is (scalar $h -> get ([]), scalar $h -> data (), 'Data = Get');
is_deeply (scalar $h -> get (''), scalar $h -> data (), 'Data = Get (deeply)');
is_deeply (scalar $h -> get ([]), scalar $h -> data (), 'Data = Get (deeply)');

# same with copying:
%a = $h -> get ('');
isnt ($a -> {'a'}, $data -> {'a'}, 'Ref #1 ok');
isnt ($a -> {'b'}, $data -> {'b'}, 'Ref #2 ok');

# some more tests with an arrayref as root element:
$data = [
	'A',                            # 0
	[                               # 1
		sub {},                 # 1/0
		[                       # 1/1
			'B10',          # 1/1/0
			'B11'           # 1/1/1
		],
		{                       # 1/2
			'b2' => 'B2'    # 1/2/b2
		},
	],
	{                               # 2
		'c1' => 'C1',           # 2/c1
		'c2' => [               # 2/c2
			'C20',          # 2/c2/0
			undef           # 2/c2/1
		]
	},
];

%expected = (
	'///'           => $data,
	'xyz'           => undef,
	'3'             => undef,
	'//0'           => $data -> [0],
	'1'             => $data -> [1],
	'1/0//'         => $data -> [1] [0],
	'1/1'           => $data -> [1] [1],
	'1/1/0'         => $data -> [1] [1] [0],
	'1/2'           => $data -> [1] [2],
	'1///2//b2'     => $data -> [1] [2] {'b2'},
	'2'             => $data -> [2],
	'2/c1'          => $data -> [2] {'c1'},
	'2/c2'          => $data -> [2] {'c2'},
	'/2/c2/1/'      => $data -> [2] {'c2'} [1],
);

$h = Data::SimplePath -> new ($data);

is_deeply (scalar $h -> data (), $data, 'Array structure ok after init');

no warnings 'Data::SimplePath'; # let's try with warnings disabled...
while (my ($k, $v) = each %expected) {
	is ($h -> get ($k), $v, "$k ok (array)");
	# not normalized, but empty array elements should be skipped:
	my @p = split '/', $k;
	is ($h -> get (\@p), $v, "$k split ok (array)");
}
use warnings;

# storable does not like code refs:
$data -> [1] [0] = 'qr/.*/';

# in list context a copy must be returned:
%a = $h -> get ('2');
is_deeply (\%a, $data -> [2], '% ok');
isnt ($a {'c2'}, $data -> [2] {'c2'}, 'Ref %1 ok');

# same for an array instead of a hash:
@b = $h -> get ('1');
is_deeply (\@b, $data -> [1], '@ ok');
isnt ($b [1], $data -> [1] [1], 'Ref @1 ok');
isnt ($b [2], $data -> [1] [2], 'Ref @2 ok');

# with the empty key, it must return the same results as the data method:
is (scalar $h -> get (''), scalar $h -> data (), 'Data = Get');
is (scalar $h -> get ([]), scalar $h -> data (), 'Data = Get');
is_deeply (scalar $h -> get (''), scalar $h -> data (), 'Data = Get (deeply)');
is_deeply (scalar $h -> get ([]), scalar $h -> data (), 'Data = Get (deeply)');

# same with copying:
@b = $h -> get ('');
isnt ($b -> [1], $data -> [1], 'Ref #1 ok');
isnt ($b -> [2], $data -> [2], 'Ref #2 ok');

# Devel::Cover should be all green:
is ($h -> get ([1, [], 2, {}, 'xyz']), undef, 'Ref test #1');
is ($h -> get ([ {}, [], \$h, sub {}, 0 ]), $data -> [0], 'Ref test #2');
