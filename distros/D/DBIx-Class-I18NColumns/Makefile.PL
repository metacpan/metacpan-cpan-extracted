use inc::Module::Install;

name 'DBIx-Class-I18NColumns';
all_from 'lib/DBIx/Class/I18NColumns.pm';

requires 'parent';
requires 'DBIx::Class';

test_requires 'Test::More' => '0.88';
test_requires 'DBD::SQLite' => '1.29';
test_requires 'SQL::Translator' => '0.11005';

auto_install;
WriteAll;

