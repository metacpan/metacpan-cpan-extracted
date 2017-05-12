use inc::Module::Install;

name 'Catalyst-Plugin-DBIC-Schema-Profiler';
all_from 'lib/Catalyst/Plugin/DBIC/Schema/Profiler.pm';

build_requires 'Test::More';
build_requires 'Test::Warn';

requires 'DBIx::Class',                   '0.08115';
requires 'Catalyst',                      '5.80016';
requires 'Catalyst::Model::DBIC::Schema', '0.35';

auto_include;
WriteAll;

