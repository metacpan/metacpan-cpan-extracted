use inc::Module::Install;

name     'Acme-Testing';
all_from 'lib/Acme/Testing.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'perl';

build_requires 'Test::More';
requires 'Class::Monkey';

auto_install;

WriteAll;

