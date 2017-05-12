use inc::Module::Install;

name     'DBIx-Class-CustomPrefetch';
all_from 'lib/DBIx/Class/CustomPrefetch.pm';
author   'Andrey Kostenko <andrey@kostenko.name>';
license  'perl';

build_requires 'Test::More';
requires 'DBIx::Class', '0.081';
requires 'Module::Load';
requires 'parent';
requires 'Sub::Name';
requires 'DBIx::Class::VirtualColumns';
repository 'http://developers.rambler.ru/svn/perlmodules/DBIx-Class-CustomPrefetch/trunk';

auto_install;

WriteAll;

