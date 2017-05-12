use inc::Module::Install;
name 'App-CLI-Extension';
all_from 'lib/App/CLI/Extension.pm';

requires
      "App::CLI"                 => '0.313',
      "Class::Accessor::Grouped" => '0.1',
      "UNIVERSAL::require"       => '0.13',
      "MRO::Compat"              => '0.11',
      "Error"                    => '0.17',
     ;
auto_set_repository;

test_requires 'Test::More';
tests 't/*.t';
author_tests 'xt';
WriteAll;
