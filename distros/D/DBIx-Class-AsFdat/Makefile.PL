use strict;
use warnings;
use inc::Module::Install;

name     'DBIx-Class-AsFdat';
all_from 'lib/DBIx/Class/AsFdat.pm';

requires 'DBIx::Class';
requires 'Scalar::Util';

use_test_base;
build_requires 'Test::Declare';
build_requires 'DateTime';

auto_install;
WriteAll;

