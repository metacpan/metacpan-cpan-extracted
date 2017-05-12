use strict;
use inc::Module::Install;

name('Data-ResourceSet');
all_from('lib/Data/ResourceSet.pm');

requires('Moose');

test_requires 'Test::More';

auto_include;
WriteAll;