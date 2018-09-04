
use strict;
use warnings;

use FindBin;
use lib map "${FindBin::Bin}/$_", qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;
use Sample::Context::Singleton::Frame::Builder::Base;

use Context::Singleton::Frame::Builder::Base;

class_under_test 'Context::Singleton::Frame::Builder::Base';

my $SAMPLE_BUILDER = 'Sample::Context::Singleton::Frame::Builder::Base::__::Builder';
my $EXAMPLE_CLASS = 'Example::Test::Builder::Base';
my $EXAMPLE_DEDUCE = 'example-deduce';

sub with_deduced {
	+{
		foo => 'Foo',
		bar => 'Bar',
		$EXAMPLE_CLASS => $SAMPLE_BUILDER,
		$EXAMPLE_DEDUCE => bless {}, $SAMPLE_BUILDER,
	};
}

describe 'build ()' => as {
	use_sample_class 'Builtin::Deps';

	context "with 'as' builder" => as {
		build_instance [ as => sub { [ 'as', @_ ] } ];

		plan tests => 1;

		expect_build      expect => [ 'as', 'Foo', 'Bar' ],
			with_deduced => with_deduced,
			;
		return;
	};

	context "with method builder" => as {
		build_instance [
			this    => $EXAMPLE_CLASS,
			builder => 'new',
		];

		plan tests => 1;

		expect_build      expect => obj_isa ($SAMPLE_BUILDER),
			with_deduced => with_deduced,
			;

		return;
	};

	context 'with class::method builder' => as {
		build_instance [
			this   => $EXAMPLE_CLASS,
			call   => 'method',
		];

		plan tests => 1;

		expect_build      expect => [ 'Foo', 'Bar' ],
			with_deduced => with_deduced,
			;

		return;
	};

	return;
};

describe "Builtin::Deps" => as {
	use_sample_class 'Builtin::Deps';

	context "without dependencies" => as {
		build_instance;

		plan tests => 5;

		expect_required   expect => ['foo', 'bar'];
		expect_unresolved expect => ['foo', 'bar'];
		expect_dep        expect => undef;
		expect_default    expect => {};
		expect_build_args expect => [ 'Foo', 'Bar' ],
			with_deduced => with_deduced,
			;

		return;
	};

	context 'with this, defaults, and deps' => as {
		build_instance [
			this => $EXAMPLE_CLASS,
			builder => 'new',
			dep => [ 'some', 'deps' ],
			default => { bar => 10 },
		];

		plan tests => 5;

		expect_required   expect => [ $EXAMPLE_CLASS, 'foo', 'bar' ];
		expect_unresolved expect => [ $EXAMPLE_CLASS, 'foo' ];
		expect_dep        expect => [ 'some', 'deps' ];
		expect_default    expect => { bar => 10 };
		expect_build_args expect => [ $SAMPLE_BUILDER, 'Foo', 'Bar' ],
			with_deduced => with_deduced,
			;

		return;
	};

	context 'with this' => as {
		build_instance [
			this => $EXAMPLE_DEDUCE,
			builder => 'method',
		];

		plan tests => 5;

		expect_required   expect => [ $EXAMPLE_DEDUCE, 'foo', 'bar' ];
		expect_unresolved expect => [ $EXAMPLE_DEDUCE, 'foo', 'bar' ];
		expect_dep        expect => undef;
		expect_default    expect => {};
		expect_build_args expect => [ obj_isa ($SAMPLE_BUILDER), 'Foo', 'Bar' ],
			with_deduced => with_deduced,
			;

		return;
	};

	context 'with this and default' => as {
		build_instance [
			this  => $EXAMPLE_CLASS,
			call   => 'method',
			default => { foo => 1, bar => 2 },
		];

		plan tests => 5;

		expect_required   expect => [ $EXAMPLE_CLASS, 'foo', 'bar' ];
		expect_unresolved expect => [ $EXAMPLE_CLASS ];
		expect_dep        expect => undef;
		expect_default    expect => { bar => 2, foo => 1 };
		expect_build_args expect => [ $SAMPLE_BUILDER, 'Foo', 'Bar' ],
			with_deduced => with_deduced,
			;
		return;
	};

	return;
};

done_testing;

