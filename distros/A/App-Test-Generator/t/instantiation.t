#!/usr/bin/env perl
use strict;
use warnings;

use PPI;
# use Test::DescribeMe qw(extended);
use Test::Most;

BEGIN { use_ok('App::Test::Generator::SchemaExtractor') }

# -------------------------------------------------------------------
# Create a minimal dummy SchemaExtractor object
# -------------------------------------------------------------------
my $dummy_doc = PPI::Document->new( \'package Locale::Places; 1;' );	# Minimal PPI::Document

my $se = App::Test::Generator::SchemaExtractor->new({ input_file => __FILE__ });
$se->{_document} = $dummy_doc;	# override with dummy PPI::Document

# -------------------------------------------------------------------
# Mock _detect_instance_method for testing instance-only methods
# -------------------------------------------------------------------
{
	no warnings 'redefine';
	*App::Test::Generator::SchemaExtractor::_detect_instance_method = sub {
		my ($self, $method_name, $method_body) = @_;

		# Instance method: translate
		if ($method_name eq 'translate') {
			return {
				explicit_self	 => 1,
				shift_self		=> 0,
				accesses_object_data => 1,
			};
		}

		# Factory override example
		if ($method_name eq 'factory_method') {
			return {
				explicit_self	 => 1,
				shift_self		=> 0,
				accesses_object_data => 1,
			};
		}

		return;
	};
}

# -------------------------------------------------------------------
# Mock _detect_factory_method
# -------------------------------------------------------------------
{
	no warnings 'redefine';
	*App::Test::Generator::SchemaExtractor::_detect_factory_method = sub {
		my ($self, $method_name, $method_body, $current_package, $method_info) = @_;

		if ($method_name eq 'factory_method') {
			return {
				returns_class => 'Locale::Places',
				returns_new => 1,
				confidence => 'high',
			};
		}

		return;
	};
}

# -------------------------------------------------------------------
# Test instance-only method detection
# -------------------------------------------------------------------
my $pkg = $se->_needs_object_instantiation('translate', q{}, {});
ok($pkg, 'translate requires object instantiation');
is($pkg, 'Locale::Places', 'Correct package detected for instance method');

# -------------------------------------------------------------------
# Test factory method overridden by instance
# -------------------------------------------------------------------
$pkg = $se->_needs_object_instantiation('factory_method', q{}, {});
ok($pkg, 'Instance method detection overrides factory');
is($pkg, 'Locale::Places', 'Factory method overridden correctly');

done_testing();

