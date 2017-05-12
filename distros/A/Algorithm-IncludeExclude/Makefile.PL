use inc::Module::Install;
use strict;
use warnings;

name 'Algorithm-IncludeExclude';
all_from 'lib/Algorithm/IncludeExclude.pm';
requires 'Carp';
build_requires 'Test::More';
build_requires 'Test::Exception';
auto_install;
WriteAll;
