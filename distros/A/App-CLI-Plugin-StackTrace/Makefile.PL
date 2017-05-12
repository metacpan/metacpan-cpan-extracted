use inc::Module::Install;
name 'App-CLI-Plugin-StackTrace';
all_from 'lib/App/CLI/Plugin/StackTrace.pm';

requires(
	"App::CLI::Extension" => 1.2,
	"Devel::StackTrace"   => 1.0
);

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
sign;
WriteAll;
