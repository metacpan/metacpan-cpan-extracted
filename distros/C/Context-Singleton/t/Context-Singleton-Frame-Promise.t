
use v5.10;
use strict;
use warnings;

use FindBin;
use lib map qq (${FindBin::Bin}/$_), qw[ ../lib lib sample ];

use Test::Spec::Util;
use Hash::Util;

use Context::Singleton::Frame::Promise;
use Context::Singleton::Frame::Promise::Rule;
use Context::Singleton::Frame::Promise::Builder;

sub build {
	my (@params) = @_;

	my $class = shared->class;

	return
		unless $class
		;

	$class->new( @params );
}

sub behaves_like_method {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params, qw[ object method method_args throws expect expected ];

	$params{object} //= shared->object;
	$params{expect} = $params{expected}
		if exists $params{expected}
		;

	test_method $title => (
		object => $params{object},
		(throws => $params{throws}) x exists $params{throws},
		(expect => $params{expect}) x exists $params{expect},
	);
}

sub expect_deduced {
	my $title = shift
		if @_ % 2
		;

	shared->method = q (is_deduced);
	shared->method_args = [];

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	$params{expect} //= bool (1);

	$title //= q (shoud throw)
		if $params{throws}
		;
	$title //= qq (should ${\ (eq_deeply (0, $params{expect}) ? 'not ' : '') }be resolved);

	behaves_like_method $title => %params;
}

sub expect_not_deduced {
	expect_deduced @_, expect => bool (0);
}

sub expect_deducible {
	my $title = shift
		if @_ % 2
		;

	shared->method = q (is_deducible);
	shared->method_args = [];

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	$params{expect} //= bool (1);

	$title //= q (shoud throw)
		if $params{throws}
		;
	$title //= qq (should ${\ (eq_deeply (0, $params{expect}) ? 'not ' : '') }be resolvable);

	behaves_like_method $title => %params;
}

sub expect_not_deducible {
	expect_deducible @_, expect => bool (0);
}

sub expect_deduced_in_depth {
	my $title = shift
		if @_ % 2
		;

	shared->method = q (deduced_in_depth);
	shared->method_args = [];

	$title //= q (should be deduced in depth);

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	behaves_like_method $title => %params;
}

sub expect_value {
	my $title = shift
		if @_ % 2
		;

	shared->method = q (value);
	shared->method_args = [];

	$title //= q (should have value);

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	behaves_like_method $title => %params;
}

sub expect_deducible_builder {
	my $title = shift
		if @_ % 2
		;

	shared->method = q (deducible_builder);
	shared->method_args = [];

	$title //= q (should have deduced dependency);

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	behaves_like_method $title => %params;
}

describe q (Context::Singleton::Frame::Promise) => as {
	shared->class = q (Context::Singleton::Frame::Promise);

	plan tests => 1;

	describe q (new()) => as {
		plan tests => 4;

		describe q (new promise is not deduced neither deducible) => as {
			shared->object = build (depth => 4);

			plan tests => 3;

			expect_not_deduced;
			expect_not_deducible;
			expect_value expect => undef;
		};

		describe q (after set_deducible is deducible in notified depth) => as {
			shared->object = my $promise = build (depth => 4);
			$promise->set_deducible (2);

			plan tests => 4;

			expect_not_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 2;
			expect_value expect => undef;
		};

		describe q (deduced promise (with default depth)) => as {
			shared->object = my $promise = build (depth => 4);
			$promise->set_value (q (value));

			plan tests => 4;

			expect_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 4;
			expect_value expect => q (value);
		};

		describe q (deduced promise (with injected depth)) => as {
			shared->object = my $promise = build (depth => 4);
			$promise->set_value (q (value), 3);

			plan tests => 4;

			expect_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 3;
			expect_value expect => q (value);
		};

		return;
	};

	return;
};

describe q (Context::Singleton::Frame::Promise::Rule) => as {
	shared->class = q (Context::Singleton::Frame::Promise::Rule);

	context q (construct dependencies) => as {
		shared->object = my $promise = build (depth => 4);
		my $dep_001 = build (depth => 1);
		my $dep_002 = build (depth => 2);

		$promise->add_dependencies ($dep_001, $dep_002);

		context q (initialized promise) => as {
			plan tests => 2;

			expect_not_deduced;
			expect_not_deducible;
		};

		context q (with deduced dependency in depth 1 should become deducible) => as {
			$dep_001->set_value (q (aaa));

			plan tests => 4;

			expect_not_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 1;
			expect_deducible_builder expect => $dep_001;
		};

		context q (with deduced dependency in depth 2 should override deduced_in_depth) => as {
			$dep_002->set_value (q (bbb));

			plan tests => 4;

			expect_not_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 2;
			expect_deducible_builder expect => $dep_002;
		};

		return;
	};

	context q (attach to already deduced dependency) => as {
		shared->object = my $promise = build (depth => 4);
		my $dep_001 = build (depth => 1);
		my $dep_002 = build (depth => 2);

		$dep_001->set_value (q (aaa));
		$promise->add_dependencies ($dep_001, $dep_002);

		plan tests => 4;

		expect_not_deduced;
		expect_deducible;
		expect_deduced_in_depth expect => 1;
		expect_deducible_builder expect => $dep_001;
	};

	context q (with recursive dependencies) => as {
		my $promise = build (depth => 4);
		my $dep_001 = build (depth => 4);
		my $dep_002 = build (depth => 4);

		$promise->add_dependencies ($dep_001);
		$dep_001->add_dependencies ($dep_002);
		$dep_002->add_dependencies ($promise);

		plan tests => 2;

		context q (initialized) => as {
			plan tests => 3;

			context q (promise under test) => as {
				shared->object = $promise;

				plan tests => 2;

				expect_not_deduced;
				expect_not_deducible;
			};

			context q (dependency 1) => as {
				shared->object = $dep_001;

				plan tests => 2;

				expect_not_deduced;
				expect_not_deducible;
			};

			context q (dependency 2) => as {
				shared->object = $dep_002;

				plan tests => 2;

				expect_not_deduced;
				expect_not_deducible;
			};

			return;
		};

		context q (after setting deducible) => as {
			plan tests => 3;
			$dep_002->set_value (q (aaa), 2);

			context q (promise under test) => as {
				shared->object = $promise;

				plan tests => 3;

				expect_not_deduced;
				expect_deducible;
				expect_deduced_in_depth expect => 2;
			};

			context q (dependency 1) => as {
				shared->object = $dep_001;

				plan tests => 3;

				expect_not_deduced;
				expect_deducible;
				expect_deduced_in_depth expect => 2;
			};

			context q (dependency 2) => as {
				shared->object = $dep_002;

				plan tests => 3;

				expect_deduced;
				expect_deducible;
				expect_deduced_in_depth expect => 2;
			};

			return;
		};
	};

	return;
};

describe q (Context::Singleton::Frame::Promise::Builder) => as {
	shared->class = q (Context::Singleton::Frame::Promise::Builder);

	shared->object = my $promise = build (depth => 5);
	my $dep_001 = build (depth => 1);
	my $dep_002 = build (depth => 2);
	my $lis_003 = build (depth => 3);
	my $lis_004 = build (depth => 4);

	$promise->add_dependencies ($dep_001, $dep_002);
	$promise->listen ($lis_003, $lis_004);

	context q (initialized promise with two dependencies) => as {
		plan tests => 2;

		expect_not_deduced;
		expect_not_deducible;
	};

	context q (with deduced one dependency should not be deducible) => as {
		$dep_001->set_value (q (aaa), 1);

		plan tests => 2;

		expect_not_deduced;
		expect_not_deducible;
	};

	context q (with deduced both dependencies should be deducible) => as {
		$dep_002->set_value (q (bbb), 2);

		plan tests => 3;

		expect_not_deduced;
		expect_deducible;
		expect_deduced_in_depth expect => 2;
	};

	context q (with deduced listener (optional) deduced in depth should be affected) => as {
		$lis_003->set_value (q (ccc), 3);

		plan tests => 3;

		expect_not_deduced;
		expect_deducible;
		expect_deduced_in_depth expect => 3;
	};

	return;
};

done_testing;
