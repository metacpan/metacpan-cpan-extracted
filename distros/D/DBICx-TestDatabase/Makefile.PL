use inc::Module::Install;

name 'DBICx-TestDatabase';
all_from 'lib/DBICx/TestDatabase.pm';

requires 'File::Temp';
requires 'DBD::SQLite' => '1.29';
requires 'SQL::Translator';

build_requires 'DBIx::Class';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
