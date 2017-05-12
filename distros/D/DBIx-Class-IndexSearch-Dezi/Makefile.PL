use inc::Module::Install;

name     'DBIx-Class-IndexSearch-Dezi';
all_from 'lib/DBIx/Class/IndexSearch/Dezi.pm';
author   q{Logan Bell <loganbell@gmail.com>};
license  'perl';

build_requires 'Test::More';
requires 'Moo';
requires 'Carp';
requires 'Module::Load';
requires 'DBIx::Class';

test_requires 'Test::More';
test_requires 'DBIx::Class::TimeStamp';

auto_install;

WriteAll;

