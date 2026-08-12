
use strict;
use warnings;

use FindBin;
use lib map qq (${FindBin::Bin}/$_), qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;
use Sample::Context::Singleton::Frame::Builder::Base;

use Context::Singleton::Frame::Builder::Hash;

class_under_test q (Context::Singleton::Frame::Builder::Hash);

my $SAMPLE_BUILDER = q (Sample::Context::Singleton::Frame::Builder::Base::__::Builder);
my $EXAMPLE_CLASS = q (Example::Test::Builder::Base);
my $EXAMPLE_DEDUCE = q (example-deduce);

sub build_args {
	Compare::Builder::Hash::Args->new (@_);
}

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

describe q (Builder::Hash) => as {
	context q (with empty dependencies) => as {
		context q (without 'this') => sub {
			build_instance [
				dep => { },
			];

			plan tests => 4;

			expect_required   expect => [ ];
			expect_unresolved expect => [ ];
			expect_dep        expect => { };
			expect_build_args expect => [ ];

			return;
		};

		context q (with this) => sub {
			build_instance [
				this => $EXAMPLE_CLASS,
				dep => { },
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_CLASS ];
			expect_unresolved expect => [ $EXAMPLE_CLASS ];
			expect_dep        expect => { };
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
				dep => { a => q (foo), b => q (bar) },
			];

			plan tests => 4;

			expect_required   expect => [ q (foo), q (bar) ];
			expect_unresolved expect => [ q (foo), q (bar) ];
			expect_dep        expect => { a => q (foo), b => q (bar) };
			expect_build_args expect => build_args (a => q (Foo), b => q (Bar)),
				with_deduced => { with_deduced },
				;

			return;
		};

		context q (with this) => sub {
			build_instance [
				this => $EXAMPLE_CLASS,
				dep => { a => q (foo), b => q (bar) },
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_CLASS, q (foo), q (bar) ];
			expect_unresolved expect => [ $EXAMPLE_CLASS, q (foo), q (bar) ];
			expect_dep        expect => { a => q (foo), b => q (bar) };
			expect_build_args expect => build_args ($SAMPLE_BUILDER, a => q (Foo), b => q (Bar)),
				with_deduced => { with_deduced },
				;

			return;
		};

		return;
	};
	return;
};

done_testing;

package Compare::Builder::Hash::Args;
use parent q (Test::Deep::Cmp);

sub init {
	my $self = shift;

	$self->{cmp_this} = shift
		if @_ % 2
		;
	$self->{cmp_val}  = { @_ };
}

sub descend {
	my ($self, $got) = @_;
	my @got_val = @$got;
	my $got_this = shift @got_val
		if @got_val % 2
		;

	my ($ok, $stack) = (1);
	($ok, $stack) = Test::Deep::descend ($got_this, $self->{cmp_this})
		if exists $self->{cmp_this}
		;

	my $hash_got = { @got_val };
	($ok, $stack) = Test::Deep::descend ($hash_got, $self->{cmp_val})
		if $ok
		;

	$self->{cmp_diag} = Test::Deep::deep_diag ($stack)
		if $stack
		;

	$ok;
}

__END__

