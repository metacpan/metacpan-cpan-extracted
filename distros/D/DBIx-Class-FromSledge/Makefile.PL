use strict;
use warnings;
use inc::Module::Install;

name     'DBIx-Class-FromSledge';
all_from 'lib/DBIx/Class/FromSledge.pm';

requires 'DBIx::Class';
requires 'Carp::Clan';

use_test_base;
auto_install;
WriteAll;

