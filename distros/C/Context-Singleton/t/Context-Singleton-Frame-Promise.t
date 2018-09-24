
use v5.10;
use strict;
use warnings;

use FindBin;
use lib map "${FindBin::Bin}/$_", qw[ ../lib lib sample ];

use Test::Spec::Util;
use Hash::Util;

use Context::Singleton::Frame::Promise;
use Context::Singleton::Frame::Promise::Rule;
use Context::Singleton::Frame::Promise::Builder;

sub build {
	my (@params) = @_;

	my $class = shared->class;

	return unless $class;

	$class->new( @params );
}

sub behaves_like_method {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params, qw[ object method method_args throws expect expected ];

	$params{object} //= shared->object;
	$params{expect} = $params{expected} if exists $params{expected};

	test_method $title => (
		object => $params{object},
		(throws => $params{throws}) x exists $params{throws},
		(expect => $params{expect}) x exists $params{expect},
	);
}

sub expect_deduced {
	my $title = shift if @_ % 2;

	shared->method = 'is_deduced';
	shared->method_args = [];

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	$params{expect} //= bool (1);

	$title //= "shoud throw" if $params{throws};
	$title //= "should ${\ (eq_deeply (0, $params{expect}) ? 'not ' : '') }be resolved";

	behaves_like_method $title => %params;
}

sub expect_not_deduced {
	expect_deduced @_, expect => bool (0);
}

sub expect_deducible {
	my $title = shift if @_ % 2;

	shared->method = 'is_deducible';
	shared->method_args = [];

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	$params{expect} //= bool (1);

	$title //= "shoud throw" if $params{throws};
	$title //= "should ${\ (eq_deeply (0, $params{expect}) ? 'not ' : '') }be resolvable";

	behaves_like_method $title => %params;
}

sub expect_not_deducible {
	expect_deducible @_, expect => bool (0);
}

sub expect_deduced_in_depth {
	my $title = shift if @_ % 2;

	shared->method = 'deduced_in_depth';
	shared->method_args = [];

	$title //= 'should be deduced in depth';

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	behaves_like_method $title => %params;
}

sub expect_value {
	my $title = shift if @_ % 2;

	shared->method = 'value';
	shared->method_args = [];

	$title //= 'should have value';

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	behaves_like_method $title => %params;
}

sub expect_deducible_builder {
	my $title = shift if @_ % 2;

	shared->method = 'deducible_builder';
	shared->method_args = [];

	$title //= 'should have deduced dependency';

	my %params = @_;
	Hash::Util::lock_keys %params, qw[ object throws expect ];

	behaves_like_method $title => %params;
}

describe 'Context::Singleton::Frame::Promise' => as {
	shared->class = 'Context::Singleton::Frame::Promise';

	plan tests => 1;

	describe "new()" => as {
		plan tests => 4;

		describe 'new promise is not deduced neither deducible' => as {
			shared->object = build (depth => 4);

			plan tests => 3;

			expect_not_deduced;
			expect_not_deducible;
			expect_value expect => undef;
		};

		describe 'after set_deducible is deducible in notified depth' => as {
			shared->object = my $promise = build (depth => 4);
			$promise->set_deducible (2);

			plan tests => 4;

			expect_not_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 2;
			expect_value expect => undef;
		};

		describe 'deduced promise (with default depth)' => as {
			shared->object = my $promise = build (depth => 4);
			$promise->set_value ('value');

			plan tests => 4;

			expect_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 4;
			expect_value expect => 'value';
		};

		describe 'deduced promise (with injected depth)' => as {
			shared->object = my $promise = build (depth => 4);
			$promise->set_value ('value', 3);

			plan tests => 4;

			expect_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 3;
			expect_value expect => 'value';
		};

		return;
	};

	return;
};

describe 'Context::Singleton::Frame::Promise::Rule' => as {
	shared->class = 'Context::Singleton::Frame::Promise::Rule';

	context "construct dependencies" => as {
		shared->object = my $promise = build (depth => 4);
		my $dep_001 = build (depth => 1);
		my $dep_002 = build (depth => 2);

		$promise->add_dependencies ($dep_001, $dep_002);

		context "initialized promise" => as {
			plan tests => 2;

			expect_not_deduced;
			expect_not_deducible;
		};

		context "with deduced dependency in depth 1 should become deducible" => as {
			$dep_001->set_value ('aaa');

			plan tests => 4;

			expect_not_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 1;
			expect_deducible_builder expect => $dep_001;
		};

		context "with deduced dependency in depth 2 should override deduced_in_depth" => as {
			$dep_002->set_value ('bbb');

			plan tests => 4;

			expect_not_deduced;
			expect_deducible;
			expect_deduced_in_depth expect => 2;
			expect_deducible_builder expect => $dep_002;
		};

		return;
	};

	context "attach to already deduced dependency" => as {
		shared->object = my $promise = build (depth => 4);
		my $dep_001 = build (depth => 1);
		my $dep_002 = build (depth => 2);

		$dep_001->set_value ('aaa');
		$promise->add_dependencies ($dep_001, $dep_002);

		plan tests => 4;

		expect_not_deduced;
		expect_deducible;
		expect_deduced_in_depth expect => 1;
		expect_deducible_builder expect => $dep_001;
	};

	context "with recursive dependencies" => as {
		my $promise = build (depth => 4);
		my $dep_001 = build (depth => 4);
		my $dep_002 = build (depth => 4);

		$promise->add_dependencies ($dep_001);
		$dep_001->add_dependencies ($dep_002);
		$dep_002->add_dependencies ($promise);

		plan tests => 2;

		context "initialized" => as {
			plan tests => 3;

			context "promise under test" => as {
				shared->object = $promise;

				plan tests => 2;

				expect_not_deduced;
				expect_not_deducible;
			};

			context "dependency 1" => as {
				shared->object = $dep_001;

				plan tests => 2;

				expect_not_deduced;
				expect_not_deducible;
			};

			context "dependency 2" => as {
				shared->object = $dep_002;

				plan tests => 2;

				expect_not_deduced;
				expect_not_deducible;
			};

			return;
		};

		context "after setting deducible" => as {
			plan tests => 3;
			$dep_002->set_value ("aaa", 2);

			context "promise under test" => as {
				shared->object = $promise;

				plan tests => 3;

				expect_not_deduced;
				expect_deducible;
				expect_deduced_in_depth expect => 2;
			};

			context "dependency 1" => as {
				shared->object = $dep_001;

				plan tests => 3;

				expect_not_deduced;
				expect_deducible;
				expect_deduced_in_depth expect => 2;
			};

			context "dependency 2" => as {
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

describe 'Context::Singleton::Frame::Promise::Builder' => as {
	shared->class = 'Context::Singleton::Frame::Promise::Builder';

	shared->object = my $promise = build (depth => 5);
	my $dep_001 = build (depth => 1);
	my $dep_002 = build (depth => 2);
	my $lis_003 = build (depth => 3);
	my $lis_004 = build (depth => 4);

	$promise->add_dependencies ($dep_001, $dep_002);
	$promise->listen ($lis_003, $lis_004);

	context "initialized promise with two dependencies" => as {
		plan tests => 2;

		expect_not_deduced;
		expect_not_deducible;
	};

	context "with deduced one dependency should not be deducible" => as {
		$dep_001->set_value ('aaa', 1);

		plan tests => 2;

		expect_not_deduced;
		expect_not_deducible;
	};

	context "with deduced both dependencies should be deducible" => as {
		$dep_002->set_value ('bbb', 2);

		plan tests => 3;

		expect_not_deduced;
		expect_deducible;
		expect_deduced_in_depth expect => 2;
	};

	context "with deduced listener (optional) deduced in depth should be affected" => as {
		$lis_003->set_value ('ccc', 3);

		plan tests => 3;

		expect_not_deduced;
		expect_deducible;
		expect_deduced_in_depth expect => 3;
	};

	return;
};

done_testing;
