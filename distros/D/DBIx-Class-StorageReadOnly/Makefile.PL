use strict;
use warnings;
use inc::Module::Install;

name     'DBIx-Class-StorageReadOnly';
all_from 'lib/DBIx/Class/StorageReadOnly.pm';
all_from 'lib/DBIx/Class/StorageReadOnly/TT.pm';

requires 'Carp::Clan';
requires 'DBIx::Class';

use_test_base;
auto_install;
WriteAll;

