use inc::Module::Install;
name 'App-CLI-Plugin-DBI';
all_from 'lib/App/CLI/Plugin/DBI.pm';

requires(
      "App::CLI::Extension"      => 1.2,
      "Class::Accessor::Grouped" => 0,
      "DBI"                      => 0,
	  "DBD::Mock"                => 0.11
    );

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
sign;
WriteAll;
