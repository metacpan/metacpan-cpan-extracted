use inc::Module::Install;
name 'App-CLI-Plugin-Parallel-ForkManager';
all_from 'lib/App/CLI/Plugin/Parallel/ForkManager.pm';

requires (
	"App::CLI::Extension"      => 1.4,
	"Parallel::ForkManager"    => 0.7,
    "Class::Accessor::Grouped" => 0,
);

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
sign;
WriteAll;
