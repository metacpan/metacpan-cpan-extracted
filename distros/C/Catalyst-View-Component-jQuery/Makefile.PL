use inc::Module::Install;

name     'Catalyst-View-Component-jQuery';
all_from 'lib/Catalyst/View/Component/jQuery.pm';
author   'David P.C. Wollmann <converter42 at gmail.com>';
license  'perl';

build_requires 'Test::More';
test_requires 'Catalyst::View::TT', '0.29';

requires 'Moose', '0.79';
requires 'JavaScript::Framework::jQuery', '0.01';
requires 'Catalyst::Plugin::ConfigLoader', '0.23';
requires 'Catalyst::Test';

auto_install;

WriteAll;

