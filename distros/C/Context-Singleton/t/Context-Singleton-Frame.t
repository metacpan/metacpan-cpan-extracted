
use strict;
use warnings;

use FindBin;
use lib map qq (${FindBin::Bin}/$_), qw[ ../lib lib sample ];

use Test::Spec::Util;
use Hash::Util;

use Examples::Context::Singleton::Frame;
use Sample::Context::Singleton::Frame;

use Context::Singleton::Frame;
my $CLASS = q (Context::Singleton::Frame);

describe q (build_frame()) => as {
	frame_constructor q (should build root frame) => do {
		my $root = $CLASS->build_frame;

		object          => $root,
		expect_depth    => 0,
	};

	frame_constructor q (should build child frame) => do {
		my $root = $CLASS->build_frame;
		my $child = $root->build_frame->build_frame;

		object          => $child,
		expect_depth    => 2,
	};

	return;
};

describe_method root_frame => [] => as {
	test_method q (root frame should return itself) => do {
		my $root = $CLASS->build_frame;

		object  => $root,
		expect  => $root,
	};

	test_method q (child frame should return root frame) => do {
		my $root = $CLASS->build_frame;
		my $frame = $root->build_frame->build_frame;

		object  => $frame,
		expect  => $root,
	};

	return;
};

describe_method _frame_by_depth => [qw[ depth ]] => as {
	test_method q (returns undef if depth less then 0 (root frame depth)) => do {
		my $root = $CLASS->build_frame;

		with_depth => -1,
		object => $root,
		expect => undef,
	};

	test_method q (returns undef if depth is greater then frame depth) => do {
		my $root = $CLASS->build_frame;
		my $child = $root->build_frame->build_frame;

		with_depth => 1,
		object => $root,
		expect => undef,
	};

	test_method q (returns expected frame) => do {
		my $root = $CLASS->build_frame;
		my $expect = $root->build_frame;         # depth 1
		my $child = $expect->build_frame->build_frame;

		with_depth => 1,
		object => $child,
		expect => $expect,
	};

	return;
};

describe_method proclaim   => [qw[ rule value ]] => as {
	shared->frame_class = q (Sample::Context::Singleton::Frame::__::Basic);

	plan tests => 7;

	test_method_proclaim q (should proclaim() rule without known builder) => do {
		object      => build_frame,
		with_rule   => q (unknown),
		with_value  => q (foo),
	};

	test_method_proclaim q (should proclaim() rule with known builder) => do {
		object      => build_frame,
		with_rule   => q (constant),
		with_value  => q (foo),
	};

	test_method_proclaim q (should throw when rule is already proclaim()-ed) => do {
		object      => build_frame (some_rule => q (bar)),
		with_rule   => q (some_rule),
		with_value  => q (foo),
		throws      => q (Context::Singleton::Exception::Deduced),
	};

	test_method_proclaim q (should throw when rule is already deduce()-ed) => do {
		my $object = build_frame;
		$object->deduce (q (constant));

		object      => $object,
		with_rule   => q (constant),
		with_value  => q (foo),
		throws      => q (Context::Singleton::Exception::Deduced),
	};

	test_method_proclaim q (should throw when rule is already deduce()-ed as dependency) => do {
		my $object = build_frame;
		$object->deduce (q (cascaded));

		object      => $object,
		with_rule   => q (constant),
		with_value  => q (foo),
		throws      => q (Context::Singleton::Exception::Deduced),
	};

	test_method_proclaim q (should proclaim() rule with known builder after its deduce() failed) => do {
		my $object = build_frame;
		$object->try_deduce (q (with_deps));

		object      => $object,
		with_rule   => q (with_deps),
		with_value  => q (foo),
	};

	test_method_proclaim q (should proclaim() rule if proclaim()-ed in parent frame) => do {
		my $parent = build_frame (some_rule => q (bar));

		object      => $parent->build_frame,
		with_rule   => q (some_rule),
		with_value  => q (foo),
	};

	return;
};

describe_method is_deduced => [qw[ rule ]]       => as {
	shared->frame_class = q (Sample::Context::Singleton::Frame::__::Basic);

	plan tests => 8;

	should_not_be_deduced   q (empty frame should not have any value deduced) => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => q (Key),
	};

	should_not_be_deduced   q (empty inherited frame should not have any value deduced) => do {
		my $object = build_frame build_frame;

		object      => $object,
		with_rule   => q (Key),
	};

	should_be_deduced       q (predefined value should be deduced) => do {
		my $object = build_frame Key => q (Value);

		object      => $object,
		with_rule   => q (Key),
	};

	should_not_be_deduced   q (inherited value should not be deduced) => do {
		my $object = build_frame build_frame Key => q (Value);

		object      => $object,
		with_rule   => q (Key),
	};

	should_be_deduced       q (after proclaim value should be deduced) => do {
		my $object = build_frame;
		$object->proclaim (Key => q (Value));

		object      => $object,
		with_rule   => q (Key),
	};

	should_be_deduced       q (after deduce() should be deduced) => do {
		my $object = build_frame;
		$object->deduce (q (constant));

		object     => $object,
		with_rule  => q (constant),
	};

	should_be_deduced       q (after cascaded deduce() should be deduced) => do {
		my $object = build_frame;
		$object->deduce (q (cascaded));

		object     => $object,
		with_rule  => q (constant),
	};

	should_not_be_deduced   q (after unsuccessful cascaded deduce() should not be deduced) => do {
		my $object = build_frame;
		$object->try_deduce (q (with_multi_deps));

		object     => $object,
		with_rule  => q (constant),
	};

	return;
};

describe_method is_deducible => [qw[ rule ]]     => as {
	shared->frame_class = q (Sample::Context::Singleton::Frame::__::Basic);

	plan tests => 7;

	should_not_be_deducible q (empty frame should not have any value deducible) => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => q (Key),
	};

	should_not_be_deducible q (empty inherited frame should not have any value deducible) => do {
		my $object = build_frame build_frame;

		object      => $object,
		with_rule   => q (Key),
	};

	should_be_deducible     q (predefined value should be deducible) => do {
		my $object = build_frame Key => q (Value);

		object      => $object,
		with_rule   => q (Key),
	};

	should_be_deducible     q (inherited value should be deducible) => do {
		my $object = build_frame build_frame Key => q (Value);

		object      => $object,
		with_rule   => q (Key),
	};

	should_be_deducible     q (after proclaim value should be deducible) => do {
		my $object = build_frame;
		$object->proclaim (Key => q (Value));

		object      => $object,
		with_rule   => q (Key),
	};

	should_be_deducible     q (after deduce() should be deducible) => do {
		my $object = build_frame;
		$object->deduce (q (constant));

		object      => $object,
		with_rule   => q (constant),
	};

	should_be_deducible     q (after cascaded deduce() should be deducible) => do {
		my $object = build_frame;
		$object->deduce (q (cascaded));

		object      => $object,
		with_rule   => q (constant),
	};

	return;
};

describe_method q (deduce) => [qw[ rule ]]         => as {
	shared->frame_class = q (Sample::Context::Singleton::Frame::__::Basic);

	plan tests => 12;

	should_not_deduce   q (should not deduce value without builder) => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => q (unknown),
	};

	should_deduce       q (should deduce value without dependencies) => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => q (constant),
		expect      => q (value-42),
	};

	should_deduce       q (should deduce value with dependencies with default values) => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => q (with_default),
		expect      => q (with_default:some:value-42),
	};

	should_deduce       q (should deduce value with dependencies and default values redefined) => do {
		my $object = build_frame (
			constant => 24,
			unknown  => q (another-value),
		);

		object      => $object,
		with_rule   => q (with_default),
		expect      => q (with_default:another-value:24),
	};

	should_deduce       q (should deduce value with dependencies and default values redefined in parent) => do {
		my $parent = build_frame (constant => 24);
		my $object = build_frame ($parent);

		object      => $object,
		with_rule   => q (with_default),
		expect      => q (with_default:some:24),
	};

	should_deduce       q (should deduce value with dependencies redefined in current frame) => do {
		my $parent = build_frame (constant => 24);
		my $object = build_frame ($parent, constant => 242);

		object      => $object,
		with_rule   => q (with_default),
		expect      => q (with_default:some:242),
	};

	should_deduce       q (should deduce value proclaim value with all dependencies) => do {
		my $parent = build_frame (constant => 24, with_default => q (proclaimed));
		my $object = build_frame ($parent);

		object      => $object,
		with_rule   => q (with_default),
		expect      => q (proclaimed),
	};

	should_not_deduce   q (should not deduce value with unresolved inherited dependencies) => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => q (inherited),
	};

	should_deduce       q (should deduce value with resolved inherited dependencies) => do {
		my $object = build_frame (unknown => q (foo));

		object      => $object,
		with_rule   => q (inherited),
		expect      => q (inherited:with_deps:foo:value-42),
	};

	should_deduce       q (should deduce value with computed dependency proclaimed) => do {
		my $object = build_frame (with_multi_deps => q (foo));

		object      => $object,
		with_rule   => q (inherited),
		expect      => q (inherited:foo),
	};

	should_deduce       q (should deduce value with computed dependency solved in parent redefined) => do {
		my $parent = build_frame (unknown => q (foo));
		$parent->deduce (q (with_multi_deps));

		my $object = build_frame ($parent, with_multi_deps => q (bar));

		object      => $object,
		with_rule   => q (inherited),
		expect      => q (inherited:bar),
	};

	should_deduce       q (should deduce value with trigger) => do {
		my $object = build_frame;
		$object->proclaim (with_trigger => q (dummy-bar));

		object      => $object,
		with_rule   => q (copy_trigger),
		expect      => q (dummy-bar),
	};

	return;
};

done_testing;

__END__

};

