use inc::Module::Install;
name 'DBIx-Class-Schema-Slave';
all_from 'lib/DBIx/Class/Schema/Slave.pm';

build_requires 'Test::More';
requires 'DBIx::Class';
requires 'DBIx::Class::Schema';
requires 'Clone';
use_test_base;
auto_include;
auto_install;
WriteAll;
