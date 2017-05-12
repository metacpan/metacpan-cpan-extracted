use inc::Module::Install;

name     'Bison';
all_from 'lib/Bison.pm';
author   q{Brad Haywood <brad@geeksware.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

