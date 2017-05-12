#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 109);
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
			'b0a'   => qr/.*/,      # b/0/b0a
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
	'a//aa//aaa'    => \($data -> {'a'} {'aa'} {'aaa'}),
	'a/aa/aaa/xyz'  => undef,
	'a/ab'          => $data -> {'a'} {'ab'},
	'//a//ab//0//'  => \($data -> {'a'} {'ab'} [0]),
	'a/ab/1'        => \($data -> {'a'} {'ab'} [1]),
	'a/ab/2'        => \($data -> {'a'} {'ab'} [2]),
	'a/ab/3'        => undef,
	'a/ac'          => \($data -> {'a'} {'ac'}),
	'a/ac/xyz'      => undef,
	'b'             => $data -> {'b'},
	'b/3'           => undef,
	'b/0'           => $data -> {'b'} [0],
	'b/0/xyz'       => undef,
	'b/0/1'         => undef,
	'b/0/b0a'       => \($data -> {'b'} [0] {'b0a'}),
	'b/1'           => $data -> {'b'} [1],
	'b/1/3'         => undef,
	'b/1/0'         => \($data -> {'b'} [1] [0]),
	'b/1/0/1'       => undef,
	'b/1/1'         => \($data -> {'b'} [1] [1]),
	'b/1/1/xyz'     => undef,
	'b/1/2'         => \($data -> {'b'} [1] [2]),
	'b/2'           => \($data -> {'b'} [2]),
	'b/2/xyz///'    => undef,
	'///c'          => \($data -> {'c'}),
);

my $h = Data::SimplePath -> new ($data);

is_deeply (scalar $h -> data (), $data, 'Structure ok after init');

while (my ($k, $v) = each %expected) {
	is ($h -> does_exist ($k), $v, "Exists for $k ok");
	my @p = split '/', $h -> normalize_key ($k);
	is ($h -> does_exist (\@p), $v, "Exists for $k (split) ok");
}

%expected = (
	'a/ab/xyz'      => undef,
	'b/xyz'         => undef,
	'b/1/xyz'       => undef,
);

while (my ($k, $v) = each %expected) {
	warning_like
		{ is ($h -> does_exist ($k), $v, "$k ok") }
		qr/Trying to access array element with non-numeric key /,
		"Warning for key $k ok";
	my @p = split '/', $h -> normalize_key ($k);
	warning_like
		{ is ($h -> does_exist (\@p), $v, "$k split ok") }
		qr/Trying to access array element with non-numeric key /,
		"Warning for split key $k ok";
}

# some tests with an arrayref as root element:
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
	'//0'           => \($data -> [0]),
	'1'             => $data -> [1],
	'1/0//'         => \($data -> [1] [0]),
	'1/1'           => $data -> [1] [1],
	'1/1/0'         => \($data -> [1] [1] [0]),
	'1/2'           => $data -> [1] [2],
	'1///2//b2'     => \($data -> [1] [2] {'b2'}),
	'2'             => $data -> [2],
	'2/c1'          => \($data -> [2] {'c1'}),
	'2/c2'          => $data -> [2] {'c2'},
	'/2/c2/1/'      => \($data -> [2] {'c2'} [1]),
);

$h = Data::SimplePath -> new ($data);

is_deeply (scalar $h -> data (), $data, 'Array structure ok after init');

no warnings 'Data::SimplePath'; # let's try with warnings disabled...
while (my ($k, $v) = each %expected) {
	is ($h -> does_exist ($k), $v, "$k ok (array)");
	# not normalized, but empty array elements must be skipped:
	my @p = split '/', $k;
	is ($h -> does_exist (\@p), $v, "$k split ok (array)");
}
use warnings;

# Devel::Cover should be all green:
is ($h -> does_exist ([1, [], 2, {}, 'xyz']), undef, 'Ref test #1');
is ($h -> does_exist ([ {}, [], \$h, sub {}, 0 ]), \($data -> [0]), 'Ref test #2');
