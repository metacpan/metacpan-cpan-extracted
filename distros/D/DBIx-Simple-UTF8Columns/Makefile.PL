use inc::Module::Install;
name 'DBIx-Simple-UTF8Columns';
all_from 'lib/DBIx/Simple/UTF8Columns.pm';

requires 'DBIx::Simple' => '1.28';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
