
use strict;
use warnings;

use FindBin;
use lib map qq (${FindBin::Bin}/$_), qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;
use Sample::Context::Singleton::Frame::Builder::Base;

use Context::Singleton::Frame::Builder::Array;

class_under_test q (Context::Singleton::Frame::Builder::Array);

my $SAMPLE_BUILDER = q (Sample::Context::Singleton::Frame::Builder::Base::__::Builder);
my $EXAMPLE_CLASS = q (Example::Test::Builder::Base);
my $EXAMPLE_DEDUCE = q (example-deduce);

sub with_dependencies {
	+( q (foo), q (bar) )
}

sub with_deduced {
	+(
		foo => q (Foo),
		bar => q (Bar),
		$EXAMPLE_CLASS => $SAMPLE_BUILDER,
		$EXAMPLE_DEDUCE => bless {}, $SAMPLE_BUILDER,
	);
}

describe q (Builder::Array) => as {
	context q (with empty dependencies) => as {
		context q (without 'this') => sub {
			build_instance [
				dep => [ ],
			];

			plan tests => 4;

			expect_required   expect => [ ];
			expect_unresolved expect => [ ];
			expect_dep        expect => [ ];
			expect_build_args expect => [ ];

			return;
		};

		context q (with this) => sub {
			build_instance [
				this => $EXAMPLE_CLASS,
				dep => [ ],
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_CLASS ];
			expect_unresolved expect => [ $EXAMPLE_CLASS ];
			expect_dep        expect => [ ];
			expect_build_args expect => [ $SAMPLE_BUILDER ],
				with_deduced => { with_deduced },
				;

			return;
		};

		return;
	};

	context q (with some dependencies) => as {
		context q (without 'this') => sub {
			build_instance [
				dep => [ q (foo), q (bar) ],
			];

			plan tests => 4;

			expect_required   expect => [ q (foo), q (bar) ];
			expect_unresolved expect => [ q (foo), q (bar) ];
			expect_dep        expect => [ q (foo), q (bar) ];
			expect_build_args expect => [ q (Foo), q (Bar) ],
				with_deduced => { with_deduced },
				;

			return;
		};

		context q (with this) => sub {
			build_instance [
				this => $EXAMPLE_CLASS,
				dep => [ q (foo), q (bar) ],
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_CLASS, q (foo), q (bar) ];
			expect_unresolved expect => [ $EXAMPLE_CLASS, q (foo), q (bar) ];
			expect_dep        expect => [ q (foo), q (bar) ];
			expect_build_args expect => [ $SAMPLE_BUILDER, q (Foo), q (Bar) ],
				with_deduced => { with_deduced },
				;

			return;
		};

		return;
	};
	return;
};

done_testing;

__END__
