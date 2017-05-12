use inc::Module::Install;
name 'App-CLI-Plugin-Daemonize';
all_from 'lib/App/CLI/Plugin/Daemonize.pm';

requires (
	"App::CLI::Extension"   => 1.2,
);

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
sign;
WriteAll;
