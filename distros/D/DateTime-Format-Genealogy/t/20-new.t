#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 7;

BEGIN {
	use_ok('DateTime::Format::Genealogy')
}

isa_ok(DateTime::Format::Genealogy->new(), 'DateTime::Format::Genealogy', 'Creating DateTime::Format::Genealogy object');
isa_ok(DateTime::Format::Genealogy::new(), 'DateTime::Format::Genealogy', 'Creating DateTime::Format::Genealogy object');
isa_ok(DateTime::Format::Genealogy->new()->new, 'DateTime::Format::Genealogy', 'Cloning DateTime::Format::Genealogy object');
# ok(!defined(DateTime::Format::Genealogy::new()));

# Create a new object with arguments as a hash
subtest 'Create object with hash arguments' => sub {
	my $obj = DateTime::Format::Genealogy->new(foo => 'bar', baz => 42);
	isa_ok($obj, 'DateTime::Format::Genealogy');
	is($obj->{foo}, 'bar', 'Attribute foo is set correctly');
	is($obj->{baz}, 42, 'Attribute baz is set correctly');
};

# Create a new object with arguments as a hashref
subtest 'Create object with hashref arguments' => sub {
	my $obj = DateTime::Format::Genealogy->new({ foo => 'bar', baz => 43 });
	isa_ok($obj, 'DateTime::Format::Genealogy');
	is($obj->{foo}, 'bar', 'Attribute foo is set correctly');
	is($obj->{baz}, 43, 'Attribute baz is set correctly');
};

# Clone an existing object with new arguments
subtest 'Clone object with new arguments' => sub {
	my $original_obj = DateTime::Format::Genealogy->new(foo => 'bar');
	my $cloned_obj = $original_obj->new(baz => 44);

	isa_ok($cloned_obj, 'DateTime::Format::Genealogy');
	is($cloned_obj->{foo}, 'bar', 'Original attribute foo is preserved');
	is($cloned_obj->{baz}, 44, 'New attribute baz is set correctly');
};
