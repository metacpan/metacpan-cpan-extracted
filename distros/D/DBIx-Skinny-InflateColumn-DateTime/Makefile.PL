use inc::Module::Install;
name 'DBIx-Skinny-InflateColumn-DateTime';
all_from 'lib/DBIx/Skinny/InflateColumn/DateTime.pm';

requires 'DBIx::Skinny' => '0.05';
requires 'DBD::SQLite';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'DateTime::Format::MySQL';
requires 'DateTime::TimeZone';

author_tests('xt');

test_requires 'Test::More';

use_test_base;
auto_include;
WriteAll;
