use strict;
use warnings;

use inc::Module::Install;

name 'Catalyst-Plugin-Environment';
all_from 'lib/Catalyst/Plugin/Environment.pm';
license 'MIT';

requires 'namespace::autoclean';
requires 'Moose::Role';

test_requires 'Catalyst';
test_requires 'Catalyst::Runtime' => 5.80;
test_requires 'Moose';
test_requires 'Test::More';

auto_install;
WriteAll;
