use inc::Module::Install;

name     'DBIx-Class-QueryProfiler';
all_from 'lib/DBIx/Class/QueryProfiler.pm';
author   q{Andrey Kostenko <andrey@kostenko.name>};
license  'perl';

build_requires 'Test::More';
requires 'parent';
requires 'DBIx::Class';
test_requires 'Test::Perl::Critic';
repository 'http://developers.rambler.ru/svn/perlmodules/DBIx-Class-QueryProfiler/';

auto_install;

WriteAll;

