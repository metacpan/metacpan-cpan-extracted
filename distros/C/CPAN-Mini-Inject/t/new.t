use strict;
use warnings;

use Test::More;

use File::Spec::Functions qw(catfile);

my $class = 'CPAN::Mini::Inject';
my $method = 'new';

subtest sanity => sub {
	use_ok $class or BAIL_OUT( "$class did not compile: $@" );
	can_ok $class, $method;
	};

subtest 'no args' => sub {
	my $mcpi = $class->$method();
	isa_ok $mcpi, $class;

	can_ok $class, 'default_config_class';
	is $mcpi->config_class, $class->default_config_class, 'received the expected default config class';

	can_ok $mcpi, 'config';
	};

done_testing();
