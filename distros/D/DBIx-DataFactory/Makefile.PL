use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorTests;

name     'DBIx-DataFactory';
author   'Yuki Shibazaki <shibayu36 {at} gmail.com>';
all_from 'lib/DBIx/DataFactory.pm';

requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'Smart::Args';
requires 'DBIx::Inspector';
requires 'DBI';
requires 'SQL::Maker';
requires 'Sub::Install';
requires 'Class::Load';
requires 'String::Random';

test_requires 'Test::More';
test_requires 'Test::Class';
test_requires 'Test::TypeConstraints';
test_requires 'Test::mysqld';
test_requires 'Path::Class';

recursive_author_tests('xt');

WriteAll;
