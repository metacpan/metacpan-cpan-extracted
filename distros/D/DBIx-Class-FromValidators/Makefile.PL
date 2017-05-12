use inc::Module::Install;
name 'DBIx-Class-FromValidators';
all_from 'lib/DBIx/Class/FromValidators.pm';

build_requires 'Test::More';
build_requires 'Catalyst';
build_requires 'Catalyst::Model::DBIC::Schema';
build_requires 'Catalyst::Plugin::FormValidator::Simple';
build_requires 'Catalyst::Test';
build_requires 'DBD::SQLite';
build_requires 'DBIx::Class';
build_requires 'DBIx::Class::Schema';
build_requires 'HTTP::Request::Common';

requires 'Carp::Clan';
requires 'DBIx::Class';

tests 't/*.t';

use_test_base;
auto_include;
WriteAll;
