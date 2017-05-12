use inc::Module::Install;
use Module::Install::ReadmeFromPod;
name 'DBIx-Skinny-ProxyTable';
all_from 'lib/DBIx/Skinny/ProxyTable.pm';
readme_from 'lib/DBIx/Skinny/ProxyTable.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

requires 'DBIx::Skinny', 0.0733;
requires 'Carp';

build_requires 'Test::More', 0.88;
build_requires 'Test::Exception';
build_requires 'Test::LoadAllModules';
build_requires 'Module::Install::ReadmeFromPod';
auto_include;
auto_set_repository;
WriteAll;
