use strict;
use warnings;
use inc::Module::Install;

name     'DBIx-Class-DigestColumns-Lite';
all_from 'lib/DBIx/Class/DigestColumns/Lite.pm';

requires 'Digest::SHA1';

use_test_base;
auto_install;
WriteAll;

