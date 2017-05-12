use inc::Module::Install 0.87;

name     'DBIx-Class-ResultSet-WithMetaData';
perl_version '5.006001';
all_from 'lib/DBIx/Class/ResultSet/WithMetaData.pm';

requires 'DBIx::Class' => 0.08100;
requires 'Method::Signatures::Simple' => 0.05;
requires 'Data::Alias';
requires 'DBIx::Class::ResultClass::HashRefInflator';

build_requires 'Test::More'       => 0.7;

tests_recursive();

auto_provides;

auto_install;

WriteAll;
