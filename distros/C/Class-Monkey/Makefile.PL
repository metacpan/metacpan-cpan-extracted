use inc::Module::Install;

name     'Class-Monkey';
all_from 'lib/Class/Monkey.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

