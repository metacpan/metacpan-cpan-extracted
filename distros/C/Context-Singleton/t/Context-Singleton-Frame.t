
use strict;
use warnings;

use FindBin;
use lib map "${FindBin::Bin}/$_", qw[ ../lib lib sample ];

use Test::Spec::Util;
use Hash::Util;

use Examples::Context::Singleton::Frame;
use Sample::Context::Singleton::Frame;

use Context::Singleton::Frame;
my $CLASS = 'Context::Singleton::Frame';

describe 'new()' => as {
	frame_constructor 'should build root frame' => do {
		my $root = $CLASS->new;

		object          => $root,
		expect_depth    => 0,
	};

	frame_constructor 'should build child frame' => do {
		my $root = $CLASS->new;
		my $child = $root->new->new;

		object          => $child,
		expect_depth    => 2,
	};

	return;
};

describe_method _root_frame => [] => as {
	test_method "root frame should return itself" => do {
		my $root = $CLASS->new;

		object  => $root,
		expect  => $root,
	};

	test_method "child frame should return root frame" => do {
		my $root = $CLASS->new;
		my $frame = $root->new->new;

		object  => $frame,
		expect  => $root,
	};

	return;
};

describe_method _frame_by_depth => [qw[ depth ]] => as {
	test_method "returns undef if depth less then 0 (root frame depth)" => do {
		my $root = $CLASS->new;

		with_depth => -1,
		object => $root,
		expect => undef,
	};

	test_method "returns undef if depth is greater then frame depth" => do {
		my $root = $CLASS->new;
		my $child = $root->new->new;

		with_depth => 1,
		object => $root,
		expect => undef,
	};

	test_method "returns expected frame" => do {
		my $root = $CLASS->new;
		my $expect = $root->new;         # depth 1
		my $child = $expect->new->new;

		with_depth => 1,
		object => $child,
		expect => $expect,
	};

	return;
};

describe_method proclaim   => [qw[ rule value ]] => as {
	shared->frame_class = 'Sample::Context::Singleton::Frame::__::Basic';

	plan tests => 7;

	test_method_proclaim "should proclaim() rule without known builder" => do {
		object      => build_frame,
		with_rule   => 'unknown',
		with_value  => 'foo',
	};

	test_method_proclaim "should proclaim() rule with known builder" => do {
		object      => build_frame,
		with_rule   => 'constant',
		with_value  => 'foo',
	};

	test_method_proclaim "should throw when rule is already proclaim()-ed" => do {
		object      => build_frame (some_rule => 'bar'),
		with_rule   => 'some_rule',
		with_value  => 'foo',
		throws      => 'Context::Singleton::Exception::Deduced',
	};

	test_method_proclaim "should throw when rule is already deduce()-ed" => do {
		my $object = build_frame;
		$object->deduce ('constant');

		object      => $object,
		with_rule   => 'constant',
		with_value  => 'foo',
		throws      => 'Context::Singleton::Exception::Deduced',
	};

	test_method_proclaim "should throw when rule is already deduce()-ed as dependency" => do {
		my $object = build_frame;
		$object->deduce ('cascaded');

		object      => $object,
		with_rule   => 'constant',
		with_value  => 'foo',
		throws      => 'Context::Singleton::Exception::Deduced',
	};

	test_method_proclaim "should proclaim() rule with known builder after its deduce() failed" => do {
		my $object = build_frame;
		$object->try_deduce ('with_deps');

		object      => $object,
		with_rule   => 'with_deps',
		with_value  => 'foo',
	};

	test_method_proclaim "should proclaim() rule if proclaim()-ed in parent frame" => do {
		my $parent = build_frame (some_rule => 'bar');

		object      => $parent->new,
		with_rule   => 'some_rule',
		with_value  => 'foo',
	};

	return;
};

describe_method is_deduced => [qw[ rule ]]       => as {
	shared->frame_class = 'Sample::Context::Singleton::Frame::__::Basic';

	plan tests => 8;

	should_not_be_deduced   'empty frame should not have any value deduced' => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => 'Key',
	};

	should_not_be_deduced   'empty inherited frame should not have any value deduced' => do {
		my $object = build_frame build_frame;

		object      => $object,
		with_rule   => 'Key',
	};

	should_be_deduced       'predefined value should be deduced' => do {
		my $object = build_frame Key => 'Value';

		object      => $object,
		with_rule   => 'Key',
	};

	should_not_be_deduced   'inherited value should not be deduced' => do {
		my $object = build_frame build_frame Key => 'Value';

		object      => $object,
		with_rule   => 'Key',
	};

	should_be_deduced       'after proclaim value should be deduced' => do {
		my $object = build_frame;
		$object->proclaim (Key => 'Value');

		object      => $object,
		with_rule   => 'Key',
	};

	should_be_deduced       'after deduce() should be deduced' => do {
		my $object = build_frame;
		$object->deduce ('constant');

		object     => $object,
		with_rule  => 'constant',
	};

	should_be_deduced       'after cascaded deduce() should be deduced' => do {
		my $object = build_frame;
		$object->deduce ('cascaded');

		object     => $object,
		with_rule  => 'constant',
	};

	should_not_be_deduced   'after unsuccessful cascaded deduce() should not be deduced' => do {
		my $object = build_frame;
		$object->try_deduce ('with_multi_deps');

		object     => $object,
		with_rule  => 'constant',
	};

	return;
};

describe_method is_deducible => [qw[ rule ]]     => as {
	shared->frame_class = 'Sample::Context::Singleton::Frame::__::Basic';

	plan tests => 7;

	should_not_be_deducible 'empty frame should not have any value deducible' => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => 'Key',
	};

	should_not_be_deducible 'empty inherited frame should not have any value deducible' => do {
		my $object = build_frame build_frame;

		object      => $object,
		with_rule   => 'Key',
	};

	should_be_deducible     'predefined value should be deducible' => do {
		my $object = build_frame Key => 'Value';

		object      => $object,
		with_rule   => 'Key',
	};

	should_be_deducible     'inherited value should be deducible' => do {
		my $object = build_frame build_frame Key => 'Value';

		object      => $object,
		with_rule   => 'Key',
	};

	should_be_deducible     'after proclaim value should be deducible' => do {
		my $object = build_frame;
		$object->proclaim (Key => 'Value');

		object      => $object,
		with_rule   => 'Key',
	};

	should_be_deducible     'after deduce() should be deducible' => do {
		my $object = build_frame;
		$object->deduce ('constant');

		object      => $object,
		with_rule   => 'constant',
	};

	should_be_deducible     'after cascaded deduce() should be deducible' => do {
		my $object = build_frame;
		$object->deduce ('cascaded');

		object      => $object,
		with_rule   => 'constant',
	};

	return;
};

describe_method 'deduce' => [qw[ rule ]]         => as {
	shared->frame_class = 'Sample::Context::Singleton::Frame::__::Basic';

	plan tests => 12;

	should_not_deduce   'should not deduce value without builder' => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => 'unknown',
	};

	should_deduce       'should deduce value without dependencies' => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => 'constant',
		expect      => 'value-42',
	};

	should_deduce       'should deduce value with dependencies with default values' => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => 'with_default',
		expect      => 'with_default:some:value-42',
	};

	should_deduce       'should deduce value with dependencies and default values redefined' => do {
		my $object = build_frame (
			constant => 24,
			unknown  => 'another-value',
		);

		object      => $object,
		with_rule   => 'with_default',
		expect      => 'with_default:another-value:24',
	};

	should_deduce       'should deduce value with dependencies and default values redefined in parent' => do {
		my $parent = build_frame (constant => 24);
		my $object = build_frame ($parent);

		object      => $object,
		with_rule   => 'with_default',
		expect      => 'with_default:some:24',
	};

	should_deduce       'should deduce value with dependencies redefined in current frame' => do {
		my $parent = build_frame (constant => 24);
		my $object = build_frame ($parent, constant => 242);

		object      => $object,
		with_rule   => 'with_default',
		expect      => 'with_default:some:242',
	};

	should_deduce       'should deduce value proclaim value with all dependencies' => do {
		my $parent = build_frame (constant => 24, with_default => 'proclaimed');
		my $object = build_frame ($parent);

		object      => $object,
		with_rule   => 'with_default',
		expect      => 'proclaimed',
	};

	should_not_deduce   'should not deduce value with unresolved inherited dependencies' => do {
		my $object = build_frame;

		object      => $object,
		with_rule   => 'inherited',
	};

	should_deduce       'should deduce value with resolved inherited dependencies' => do {
		my $object = build_frame (unknown => 'foo');

		object      => $object,
		with_rule   => 'inherited',
		expect      => 'inherited:with_deps:foo:value-42',
	};

	should_deduce       'should deduce value with computed dependency proclaimed' => do {
		my $object = build_frame (with_multi_deps => 'foo');

		object      => $object,
		with_rule   => 'inherited',
		expect      => 'inherited:foo',
	};

	should_deduce       'should deduce value with computed dependency solved in parent redefined' => do {
		my $parent = build_frame (unknown => 'foo');
		$parent->deduce ('with_multi_deps');

		my $object = build_frame ($parent, with_multi_deps => 'bar');

		object      => $object,
		with_rule   => 'inherited',
		expect      => 'inherited:bar',
	};

	should_deduce       'should deduce value with trigger' => do {
		my $object = build_frame;
		$object->proclaim (with_trigger => 'dummy-bar');

		object      => $object,
		with_rule   => 'copy_trigger',
		expect      => 'dummy-bar',
	};

	return;
};

done_testing;

__END__

};

