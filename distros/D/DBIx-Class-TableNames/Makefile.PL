use strict;
use warnings;
use inc::Module::Install;

name     'DBIx-Class-TableNames';
all_from 'lib/DBIx/Class/TableNames.pm';

requires 'Carp::Clan';
requires 'DBIx::Class';

use_test_base;
build_requires 'Test::More';
build_requires 'Test::Declare';

auto_install;
WriteAll;

