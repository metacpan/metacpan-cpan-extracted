
use strict;
use warnings;

use FindBin;
use lib map qq (${FindBin::Bin}/$_), qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;
use Sample::Context::Singleton::Frame::Builder::Base;

use Context::Singleton::Frame::Builder::Base;

class_under_test q (Context::Singleton::Frame::Builder::Base);

my $SAMPLE_BUILDER = q (Sample::Context::Singleton::Frame::Builder::Base::__::Builder);
my $EXAMPLE_CLASS = q (Example::Test::Builder::Base);
my $EXAMPLE_DEDUCE = q (example-deduce);

sub with_deduced {
	+{
		foo => q (Foo),
		bar => q (Bar),
		$EXAMPLE_CLASS => $SAMPLE_BUILDER,
		$EXAMPLE_DEDUCE => bless {}, $SAMPLE_BUILDER,
	};
}

describe q (build ()) => as {
	use_sample_class q (Builtin::Deps);

	context q (with 'as' builder) => as {
		build_instance [ as => sub { [ q (as), @_ ] } ];

		plan tests => 1;

		expect_build      expect => [ q (as), q (Foo), q (Bar) ],
			with_deduced => with_deduced,
			;
		return;
	};

	context q (with method builder) => as {
		build_instance [
			this    => $EXAMPLE_CLASS,
			builder => q (new),
		];

		plan tests => 1;

		expect_build      expect => obj_isa ($SAMPLE_BUILDER),
			with_deduced => with_deduced,
			;

		return;
	};

	context q (with class::method builder) => as {
		build_instance [
			this   => $EXAMPLE_CLASS,
			call   => q (method),
		];

		plan tests => 1;

		expect_build      expect => [ q (Foo), q (Bar) ],
			with_deduced => with_deduced,
			;

		return;
	};

	return;
};

describe q (Builtin::Deps) => as {
	use_sample_class q (Builtin::Deps);

	context q (without dependencies) => as {
		build_instance;

		plan tests => 5;

		expect_required   expect => [q (foo), q (bar)];
		expect_unresolved expect => [q (foo), q (bar)];
		expect_dep        expect => undef;
		expect_default    expect => {};
		expect_build_args expect => [ q (Foo), q (Bar) ],
			with_deduced => with_deduced,
			;

		return;
	};

	context q (with this, defaults, and deps) => as {
		build_instance [
			this => $EXAMPLE_CLASS,
			builder => q (new),
			dep => [ q (some), q (deps) ],
			default => { bar => 10 },
		];

		plan tests => 5;

		expect_required   expect => [ $EXAMPLE_CLASS, q (foo), q (bar) ];
		expect_unresolved expect => [ $EXAMPLE_CLASS, q (foo) ];
		expect_dep        expect => [ q (some), q (deps) ];
		expect_default    expect => { bar => 10 };
		expect_build_args expect => [ $SAMPLE_BUILDER, q (Foo), q (Bar) ],
			with_deduced => with_deduced,
			;

		return;
	};

	context q (with this) => as {
		build_instance [
			this => $EXAMPLE_DEDUCE,
			builder => q (method),
		];

		plan tests => 5;

		expect_required   expect => [ $EXAMPLE_DEDUCE, q (foo), q (bar) ];
		expect_unresolved expect => [ $EXAMPLE_DEDUCE, q (foo), q (bar) ];
		expect_dep        expect => undef;
		expect_default    expect => {};
		expect_build_args expect => [ obj_isa ($SAMPLE_BUILDER), q (Foo), q (Bar) ],
			with_deduced => with_deduced,
			;

		return;
	};

	context q (with this and default) => as {
		build_instance [
			this  => $EXAMPLE_CLASS,
			call   => q (method),
			default => { foo => 1, bar => 2 },
		];

		plan tests => 5;

		expect_required   expect => [ $EXAMPLE_CLASS, q (foo), q (bar) ];
		expect_unresolved expect => [ $EXAMPLE_CLASS ];
		expect_dep        expect => undef;
		expect_default    expect => { bar => 2, foo => 1 };
		expect_build_args expect => [ $SAMPLE_BUILDER, q (Foo), q (Bar) ],
			with_deduced => with_deduced,
			;
		return;
	};

	return;
};

done_testing;

