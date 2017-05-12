use inc::Module::Install;

name     'DBIx-Class-ResultSet-Faceter';
all_from 'lib/DBIx/Class/ResultSet/Faceter.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

test_requires 'MooseX::Iterator';

requires 'DateTime';
requires 'Moose';
requires 'MooseX::Iterator';
requires 'MooseX::Types';
requires 'DBIx::Class';
requires 'Try::Tiny';

repository 'http://github.com/gphat/dbix-class-resultset-faceter';

WriteAll;

