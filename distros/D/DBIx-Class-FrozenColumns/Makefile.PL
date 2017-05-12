use inc::Module::Install 0.67;

name     'DBIx-Class-FrozenColumns';
all_from 'lib/DBIx/Class/FrozenColumns.pm';

requires       'DBIx::Class' => 0.07003;
requires       'Storable'    => 2.15;
requires       'JSON::XS';
build_requires 'DBD::SQLite' => 1.13;

auto_install;
WriteAll;
