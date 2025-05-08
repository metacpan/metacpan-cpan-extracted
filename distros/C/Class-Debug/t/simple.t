use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Class::Debug') }

# Fake class name for testing
my $class = 'My::Test::Class';

# Basic test: no config file, no logger provided
my $params = {
	foo => 'bar',
};

my $result = Class::Debug::setup($class, $params);

ok(ref $result eq 'HASH', 'setup returned a hashref');
is($result->{foo}, 'bar', 'original param preserved');

ok($result->{logger}, 'logger initialized');
is(ref $result->{logger}, 'Log::Abstraction', 'logger is a Log::Abstraction object');

# Provide a dummy logger
my $custom_logger = sub { warn "log: @_" };

$result = Class::Debug::setup($class, {
	foo => 'bar',
	logger => $custom_logger,
});

isa_ok($result->{logger}, 'Log::Abstraction', 'custom logger wrapped in Log::Abstraction');

# Provide a syslog logger hash
$result = Class::Debug::setup($class, {
	foo => 'bar',
	logger => { syslog => 'local0' },
});

isa_ok($result->{logger}, 'Log::Abstraction', 'syslog logger also wrapped');

# Test bad config file (file not readable or missing)
my $bad_file = '/nonexistent/config.yml';
throws_ok {
	Class::Debug::setup($class, {
		config_file => $bad_file,
	});
} qr/File not readable/, 'throws on unreadable config file';

done_testing();
