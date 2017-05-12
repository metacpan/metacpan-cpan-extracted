use strict;
use inc::Module::Install;

name('Class-Data-ConfigHash');
all_from('lib/Class/Data/ConfigHash.pm');
requires('Class::Data::Inheritable');
build_requires('Test::More');
auto_include;
WriteAll;