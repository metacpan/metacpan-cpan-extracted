#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 1176); # mh, wasn't supposed to include that many tests...
}

no warnings 'once'; # because of the globs in the test data

# example initial data to test:
my @data = (

	# valid data (7):
	[
		undef,		# data to test
		0		# set to 1 if this data must cause a warning
	],

	[ [], 0 ], [ {}, 0 ], [ [{},[]], 0 ], [ {'x'=>[]}, 0 ],

	[ [1, 2, [ 'a', 'b', 'c', {'x' => 'y'} ], { 'd' => 'e', 'f' => [sub {}] } ], 0 ],
	[ { 'a' => 'b', 'c' => qr/.*/, 'd' => [1, 2, {'x' => 'y'}], 'e' => {'0' => undef} }, 0 ],

	# invalid data (6):
	[ 'a', 1 ], [ sub {}, 1 ], [ qr/.*/, 1 ], [ \('x'), 1 ], [ *d, 1 ], [ v1.0, 1 ]

);

# example configuration data to test:
my @conf = (

	# valid data (8):
	[
		undef,		# config (supplied to new ())
		1, 1, '/'	# expected auto_array, replace_leaf & separator
	],

	[ { 'AUTO_ARRAY'   => 0    }, 0, 1, '/'  ],
	[ { 'REPLACE_LEAF' => 0    }, 1, 0, '/'	 ],
	[ { 'SEPARATOR'    => '::' }, 1, 1, '::' ],

	[ { 'AUTO_ARRAY'   => 0, 'REPLACE_LEAF' => 0   }, 0, 0, '/' ],
	[ { 'AUTO_ARRAY'   => 0, 'SEPARATOR'    => '#' }, 0, 1, '#' ],
	[ { 'REPLACE_LEAF' => 0, 'SEPARATOR'    => '*' }, 1, 0, '*' ],

	[ { 'AUTO_ARRAY' => 0, 'REPLACE_LEAF' => 0, 'SEPARATOR' => '\\'}, 0, 0, '\\' ],

	# invalid configuration data (6):
	[    'a', 1, 1, '/' ], [ sub {}, 1, 1, '/' ], [ qr/.*/, 1, 1, '/' ],
	[ \('x'), 1, 1, '/' ], [     *c, 1, 1, '/' ], [   v1.0, 1, 1, '/' ],

);

use warnings;

# iterate through the data & conf lists [$data * $conf * 6 + $data * 6 tests]:
foreach my $data (@data) {

	foreach my $conf (@conf) {

		my $h;
		my $d = $data -> [0];

		if ($data -> [1]) {
			warning_like
				{ $h = Data::SimplePath -> new ($d, $conf -> [0]); }
				qr/Discarding invalid data: .+/,
				'Invalid data warning';
			# same, with warnings disabled:
			no warnings 'Data::SimplePath';
			$h = Data::SimplePath -> new ($d, $conf -> [0]);
			use warnings;
			$d = undef;
		}
		else {
			$h = Data::SimplePath -> new ($d, $conf -> [0]);
			ok (1, 'IGNORE THIS');
		}

		# must be a Data::SimplePath object:
		isa_ok ($h, 'Data::SimplePath');

		# config must match:
		is ( $h -> auto_array   (), $conf -> [1], 'AUTO_ARRAY set to $conf->[1]'   );
		is ( $h -> replace_leaf (), $conf -> [2], 'REPLACE_LEAF set to $conf->[2]' );
		is ( $h -> separator    (), $conf -> [3], 'SEPARATOR set to $conf->[3]'    );

		# data check, if defined a deep check is done:
		if ($d) { is_deeply (scalar $h -> data (),    $d, 'Data structure ok'  ); }
		else    { is        (       $h -> data (), undef, 'Data is not defined'); }

	}

	# same as above, but without supplying any config parameter:

	my $h;
	my $d = $data -> [0];

	if ($data -> [1]) {
		warning_like
			{ $h = Data::SimplePath -> new ($d); }
			qr/Discarding invalid data: .+/,
			'Invalid data warning';
		no warnings 'Data::SimplePath';
		$h = Data::SimplePath -> new ($d);
		use warnings;
		$d = undef;
	}
	else {
		$h = Data::SimplePath -> new ($d);
		ok (1, 'IGNORE THIS');
	}

	isa_ok ($h, 'Data::SimplePath');

	is ( $h -> auto_array   (),   1, 'AUTO_ARRAY set to 1'   );
	is ( $h -> replace_leaf (),   1, 'REPLACE_LEAF set to 1' );
	is ( $h -> separator    (), '/', 'SEPARATOR set to /'    );

	if ($d) { is_deeply (scalar $h -> data (),    $d, 'Data structure ok'  ); }
	else    { is        (       $h -> data (), undef, 'Data is not defined'); }

}

# the last standard test, new without any parameters [5 tests]:
my $h = Data::SimplePath -> new ();

isa_ok ($h, 'Data::SimplePath');

is ( $h -> auto_array   (),     1, 'AUTO_ARRAY set to 1'   );
is ( $h -> replace_leaf (),     1, 'REPLACE_LEAF set to 1' );
is ( $h -> separator    (),   '/', 'SEPARATOR set to /'    );
is ( $h -> data         (), undef, 'Data is not defined'   );
