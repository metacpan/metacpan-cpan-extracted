use inc::Module::Install;

name     'Data-Rand-Obscure';
all_from 'lib/Data/Rand/Obscure.pm';
author   'Robert Krimen <rkrimen@cpan.org>';

build_requires 'Test::More';

requires qw/Carp::Clan/;
requires qw/Object::Tiny/;
requires qw/Digest/;

auto_install;

WriteAll;

