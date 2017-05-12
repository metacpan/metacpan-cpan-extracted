use inc::Module::Install;

name     'DBIx-Factory';
all_from 'lib/DBIx/Factory.pm';
author   q{Bahootyper <bahootyper@gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'Moose';
requires 'namespace::autoclean';
requires 'Scalar::Util';
requires 'Config::Any';
requires 'File::Spec';
requires 'DBI';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'FindBin';
test_requires 'YAML::XS';

WriteAll;
