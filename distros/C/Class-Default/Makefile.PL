use strict;
use inc::Module::Install;

name           'Class-Default';
all_from       'lib/Class/Default.pm';
build_requires 'Test::More'       => '0.47';

WriteAll;
