use strict;
use warnings;

use inc::Module::Install;

name     'Catalyst-Authentication-Credential-CAS';
all_from 'lib/Catalyst/Authentication/Credential/CAS.pm';
license  'MIT';

requires 'namespace::autoclean';
requires 'Authen::CAS::Client';
requires 'Moose';

test_requires 'Catalyst::Authentication::Store::Minimal';
test_requires 'Catalyst::Plugin::Authentication';
test_requires 'Catalyst::Runtime' => '5.80';
test_requires 'Catalyst::Test';
test_requires 'Test::More';

auto_install;
WriteAll;
