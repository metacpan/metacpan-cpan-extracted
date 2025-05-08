use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Class::Debug') }

# Define our test class
{
	package My::EnvTest::Class;
	use Class::Debug;

	sub new {
		my ($class, %args) = @_;
		my $params = Class::Debug::setup($class, \%args);
		return bless $params, $class;
	}
}

local %ENV;

# Mock environment variables with the expected prefix
$ENV{'My::EnvTest::Class::env_flag'} = 'true';
$ENV{'My::EnvTest::Class::level'} = 'debug';

# Create the object without passing those values explicitly
my $obj = My::EnvTest::Class->new(foo => 'bar');

isa_ok($obj, 'My::EnvTest::Class', 'object created with env overrides');

# Confirm values came from %ENV
is($obj->{env_flag}, 'true', 'env_flag read from environment');
is($obj->{level}, 'debug', 'level read from environment');

# Ensure values not set via env are preserved
is($obj->{foo}, 'bar', 'non-env value preserved');

# Logger should still be initialized
ok($obj->{logger}, 'logger initialized');
isa_ok($obj->{logger}, 'Log::Abstraction');

# Clean up environment variables
# delete $ENV{'My::EnvTest::Class::env_flag'};
# delete $ENV{'My::EnvTest::Class::level'};

done_testing();
