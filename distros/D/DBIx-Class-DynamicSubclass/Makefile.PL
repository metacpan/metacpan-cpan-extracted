use inc::Module::Install 0.67;

name     'DBIx-Class-DynamicSubclass';
all_from 'lib/DBIx/Class/DynamicSubclass.pm';

requires       'DBIx::Class'     => 0.07003;
build_requires 'DBD::SQLite'     => 1.13;
build_requires 'SQL::Translator' => 0.08;

auto_install;
WriteAll;

