use inc::Module::Install;

name 'Data-KeyDiff';
all_from 'lib/Data/KeyDiff.pm';

build_requires 'Test::More';
build_requires 'Test::Deep';

requires qw/Carp 0/;
requires qw/Object::Tiny 0/;

auto_install;

WriteAll;

