use strict;
use warnings;
use inc::Module::Install;

name 'CatalystX-FacebookURI';
all_from 'lib/CatalystX/FacebookURI.pm';
license 'perl';

# prereqs
requires 'Catalyst::Plugin::Facebook';
requires 'Moose::Role';
requires 'URI';

# things the tests need
test_requires 'Test::More';

tests('t/*.t');

WriteAll();

