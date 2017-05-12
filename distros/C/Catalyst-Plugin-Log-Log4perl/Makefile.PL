use strict;
use warnings;

use inc::Module::Install;

name 'Catalyst-Plugin-Log-Log4perl';
all_from 'lib/Catalyst/Plugin/Log/Log4perl.pm';
license 'MIT';

requires 'namespace::autoclean';
requires 'Log::Log4perl';
requires 'Moose';

test_requires 'Catalyst::Runtime' => '5.80';
test_requires 'Test::More';

auto_install;
WriteAll;
