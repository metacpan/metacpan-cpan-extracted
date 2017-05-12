use Test::Dependencies
	exclude => [qw/Test::Dependencies Test::Base Test::Perl::Critic CHI::Driver::MemcachedFast/],
	style   => 'light';
ok_dependencies();
