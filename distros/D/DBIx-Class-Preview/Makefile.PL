use inc::Module::Install 0.67;

name     'DBIx-Class-Preview';
perl_version '5.006001';
all_from 'lib/DBIx/Class/Preview.pm';

requires 'DBIx::Class' => 0.08100;
requires 'Scalar::Util' => 1.19;

build_requires 'Test::More'       => 0.7;

tests_recursive();

auto_install;

WriteAll;
