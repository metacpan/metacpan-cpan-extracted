use inc::Module::Install;
name     'DBIx-Class-Stash';
all_from 'lib/DBIx/Class/Stash.pm';

requires 'DBIx::Class';

build_requires 'Test::Declare';

use_test_base;
auto_install;
auto_set_repository
WriteAll;

