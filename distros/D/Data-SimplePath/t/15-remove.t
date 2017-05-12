#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 40);
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
	'c'                     => 'CCC',       # c
};

my $h = Data::SimplePath -> new ($data);
is_deeply (scalar $h -> data (), $data, 'Structure ok after init');

# remove the root (ie. everything):
my $del = $h -> remove ('');
is ($del, $data, 'Root ref ok');
is (scalar $h -> data (), undef, 'Data undef ok');

$h = Data::SimplePath -> new ($data);
is_deeply (scalar $h -> data (), $data, 'Structure ok after init');

# welcome to "Tests That Suck":
#       remove single elements, hashrefs or arrayrefs, and always check the remains:

my $a = $data -> {'a'};
$del = $h -> remove ('a');
is ($del, $a, 'Del a ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B11','B12'],'B2'],'c'=>'CCC'}, 'New data ok');

# ... or not existing elements - must return undef ...:
$del = $h -> remove ('c/d');
is ($del, undef, 'Del c/d ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B11','B12'],'B2'],'c'=>'CCC'}, 'New data ok');

# ... one non-existing level deeper ...:
$del = $h -> remove ('c/d/e');
is ($del, undef, 'Del c/d/e ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B11','B12'],'B2'],'c'=>'CCC'}, 'New data ok');

# b is an array, non-numeric key => warning:
no warnings 'Data::SimplePath';
$del = $h -> remove ('b/string');
is ($del, undef, 'Del b/string ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B11','B12'],'B2'],'c'=>'CCC'}, 'New data ok');
use warnings;

warning_like
	{ $del = $h -> remove ('b/string'); }
	qr/Trying to access array element with non-numeric key /,
	'Warning ok for b/string';
is ($del, undef, 'Del b/string ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B11','B12'],'B2'],'c'=>'CCC'}, 'New data ok');

# remove a leaf:
$del = $h -> remove ('c');
is ($del, 'CCC', 'Del c ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B11','B12'],'B2']}, 'New data ok');

# an array element:
$del = $h -> remove ('b/1/1');
is ($del, 'B11', 'Del b/1/1 ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B12'],'B2']}, 'New data ok');

# beyond the last array index:
$del = $h -> remove ('b/1/5');
is ($del, undef, 'Del b/1/1 ok');
is_deeply ($data, {'b'=>[{'b0a'=>qr/.*/},['B10','B12'],'B2']}, 'New data ok');

# last hash element in b/0:
$del = $h -> remove ('b/0/b0a');
is ($del, qr/.*/, 'Del b/0/b0a ok');
is_deeply ($data, {'b'=>[{},['B10','B12'],'B2']}, 'New data ok');

# remove the hashref:
my $b0 = $data -> {'b'} [0];
$del = $h -> remove ('b/0');
is ($del, $b0, 'Del b/0 ok');
is_deeply ($data, {'b'=>[['B10','B12'],'B2']}, 'New data ok');
is (scalar @{$data -> {'b'}}, 2, 'Length b ok');
is (scalar @{$data -> {'b'} [0]}, 2, 'Length b/0 ok');

# remove the last element in the root hashref:
my $b = $data -> {'b'};
$del = $h -> remove ('b');
is ($del, $b, 'Del b ok');
is_deeply ($data, {}, 'New data ok');

# some more tests, this time with an array as root:
my $s = sub {};
$data = [
		{                               # 0
			'0a' => $s,             # 0/0a
		},
		[                               # 1
			'10',                   # 1/0
			'11',                   # 1/1
			'12'                    # 1/2
		],
		'2'                             # 2
];

$h = Data::SimplePath -> new ($data);
is_deeply (scalar $h -> data (), $data, 'Structure ok after init');

# remove array element, for these tests we use the path parameter for remove ():
$del = $h -> remove ([1, 1]);
is ($del, '11', 'Del 1/1 ok');
is_deeply ($data, [{'0a'=>$s},['10','12'],'2'], 'new data ok');

# invalid stuff in the path must be ignored:
$del = $h -> remove ([0, undef, '', sub {}, '0a']);
is ($del, $s, 'Del 0/0a ok');
is_deeply ($data, [{},['10','12'],'2'], 'new data ok');

# remove the element:
$del = $h -> remove ([2]);
is ($del, '2', 'Del 2 ok');
is_deeply ($data, [{},['10','12']], 'new data ok');

# remove the root:
$del = $h -> remove ([]);
is ($del, $data, 'Del [] ok');
is_deeply ($data, [{},['10','12']], 'new data ok');
is (scalar $h -> data (), undef, 'Data is undef');
