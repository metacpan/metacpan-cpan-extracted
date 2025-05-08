use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::Most;
use YAML::XS;

BEGIN { use_ok('Class::Debug') }

# Fake class that uses Class::Debug
{
	package My::Debuggable::Class;
	use Class::Debug;

	sub new {
		my ($class, %args) = @_;
		my $params = Class::Debug::setup($class, \%args);
		return bless $params, $class;
	}
}

# Create a temporary YAML config file
my ($fh, $filename) = tempfile(SUFFIX => '.yml', UNLINK => 1);

my $config_data = {
	'My::Debuggable::Class' => {
		from_config => 'yes',
		foo => 'overridden',
	}
};

print $fh YAML::XS::Dump($config_data);
close $fh;

# Construct the object with config file and some params
my $obj = My::Debuggable::Class->new(
	config_file => $filename,
	foo => 'bar',	# this should be overridden by config
	bar => 'baz',
);

isa_ok($obj, 'My::Debuggable::Class', 'object is correctly blessed');

# Check if config merged
is($obj->{from_config}, 'yes', 'value from config file loaded');
is($obj->{foo}, 'overridden', 'default param overridden by config');
is($obj->{bar}, 'baz', 'param not overridden by config is preserved');

ok($obj->{logger}, 'logger initialized');
isa_ok($obj->{logger}, 'Log::Abstraction');

done_testing();
