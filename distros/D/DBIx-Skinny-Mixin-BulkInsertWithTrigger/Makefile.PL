use inc::Module::Install;
use Module::Install::ReadmeFromPod;
name 'DBIx-Skinny-Mixin-BulkInsertWithTrigger';
all_from 'lib/DBIx/Skinny/Mixin/BulkInsertWithTrigger.pm';
readme_from 'lib/DBIx/Skinny/Mixin/BulkInsertWithTrigger.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::Requires';
build_requires 'Test::LoadAllModules';
build_requires 'Module::Install::ReadmeFromPod';

requires 'DBIx::Skinny', 0.0710;
use_test_base;
auto_include;
WriteAll;
