use strict;
use warnings;
use lib qw(.);

use inc::Module::Install;

name     'Authen-CAS-Client';
license  'Nil';
all_from 'lib/Authen/CAS/Client.pm';

requires 'LWP';
requires 'URI';
requires 'XML::LibXML';

test_requires 'Test::MockObject';
test_requires 'Test::More';

auto_install;
WriteAll;
