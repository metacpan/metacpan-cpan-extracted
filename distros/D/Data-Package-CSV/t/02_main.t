#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 27;
use Data::Package::CSV;





#####################################################################
# Tests

SCOPE: {
	is(
		scalar(My::Test::Package1->provides('Parse::CSV')) => 1,
		'Package1->provides returns true',
	);
	my @foo = My::Test::Package1->provides('Parse::CSV');
	is(
		$foo[0] => 'Parse::CSV',
		'->provides returns Parse::CSV',
	);
	is(
		My::Test::Package1->provides('Foo') => 0,
		'->provides returns false for Foo',
	);
	my $csv1 = My::Test::Package1->get;
	isa_ok( $csv1, 'Parse::CSV' );
	my $csv2 = My::Test::Package1->get('Parse::CSV');
	isa_ok( $csv2, 'Parse::CSV' );
	is_deeply( $csv1->fetch, [ qw{ foo bar baz } ], 'Got line 1' );
	is_deeply( $csv1->fetch, [ qw{ 1   2   3   } ], 'Got line 2' );
	is_deeply( $csv1->fetch, [ qw{ a   b   c   } ], 'Got line 3' );
	is_deeply( $csv1->fetch, [ 'this', 'that', 'the other' ], 'Got line 4' );
	is( $csv1->fetch, undef, 'Got end of file' );
}

SCOPE: {
	my $csv = My::Test::Package2->get;
	is_deeply(
		$csv->fetch, { qw{ foo 1 bar 2 baz 3 } },
		'Got line 1 ok',
	);
	is_deeply(
		$csv->fetch, { qw{ foo a bar b baz c } },
		'Got line 2 ok',
	);
	is_deeply(
		$csv->fetch, {
			foo => 'this',
			bar => 'that',
			baz => 'the other',
		}, 'Got line 3 ok',
	);
	is( $csv->fetch, undef, 'Got end of file' );
}

SCOPE: {
	my $csv = My::Test::Package3->get;
	my $object1 = $csv->fetch;
	my $object2 = $csv->fetch;
	my $object3 = $csv->fetch;
	my $end     = $csv->fetch;
	isa_ok( $object1, 'My::Test::Object' );
	is( $object1->foo, 1, 'Line 1 foo ok' );
	is( $object1->bar, 2, 'Line 1 bar ok' );
	is( $object1->baz, 3, 'Line 1 baz ok' );
	isa_ok( $object2, 'My::Test::Object' );
	is( $object2->foo, 'a', 'Line 2 foo ok' );
	is( $object2->bar, 'b', 'Line 2 bar ok' );
	is( $object2->baz, 'c', 'Line 2 baz ok' );
	isa_ok( $object3, 'My::Test::Object' );
	is( $object3->foo, 'this',      'Line 3 foo ok' );
	is( $object3->bar, 'that',      'Line 3 bar ok' );
	is( $object3->baz, 'the other', 'Line 3 baz ok' );
	is( $end, undef, 'Got end of file' );
}





#####################################################################
# Test Packages

SCOPE: {
	package My::Test::Package1;

	use base 'Data::Package::CSV';

	use vars qw{$VERSION};
	BEGIN {
		$VERSION = '0.01';
	}

	sub dist_file {
		return ('Data-Package-CSV', 'test1.csv');
	}

	package My::Test::Package2;

	use base 'My::Test::Package1';

	use vars qw{$VERSION};
	BEGIN {
		$VERSION = '0.01';
	}

	sub csv_options {
		return (
			fields => 'auto',
		);
	}

	package My::Test::Object;

	sub new {
		my $class = shift;
		return bless { @_ }, $class;
	}

	sub foo { $_[0]->{foo} }

	sub bar { $_[0]->{bar} }

	sub baz { $_[0]->{baz} }

	sub as_string { $_[0]->foo . $_[0]->bar . $_[0]->baz }

	package My::Test::Package3;

	use base 'My::Test::Package2';

	use vars qw{$VERSION};
	BEGIN {
		$VERSION = '0.01';
	}

	sub csv_options {
		my $class = shift;
		return (
			$class->SUPER::csv_options,
			filter => sub {
				My::Test::Object->new(%$_),
			},
		);
	}
}
