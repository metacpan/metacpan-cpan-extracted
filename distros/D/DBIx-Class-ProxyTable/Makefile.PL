use inc::Module::Install;
name 'DBIx-Class-ProxyTable';
all_from 'lib/DBIx/Class/ProxyTable.pm';

requires 'DBIx::Class';
requires 'Carp::Clan';
requires 'UNIVERSAL::require';

use_test_base;
build_requires 'Test::More';
build_requires 'Test::Declare';

auto_include;
WriteAll;
