use inc::Module::Install;

name     'Archive-Any-Plugin-Rar';
all_from 'lib/Archive/Any/Plugin/Rar.pm';
author   q{Dmitriy V. Simonov <dsimonov@gmail.com>};
license  'perl';

build_requires 'Test::More';
build_requires 'lib::abs';
requires 'Archive::Any';
requires 'Archive::Rar';

auto_install;

WriteAll;

