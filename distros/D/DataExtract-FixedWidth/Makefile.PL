use inc::Module::Install;

name     'DataExtract-FixedWidth';
all_from 'lib/DataExtract/FixedWidth.pm';
author   'Evan <me@evancarroll.com>';
requires 'Moose' => '0.58';

perl_version '5.010';

build_requires 'Test::More';

auto_install;

WriteAll;

