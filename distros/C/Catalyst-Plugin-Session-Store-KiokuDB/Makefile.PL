use inc::Module::Install;

name 'Catalyst-Plugin-Session-Store-KiokuDB';
all_from 'lib/Catalyst/Plugin/Session/Store/KiokuDB.pm';

requires 'KiokuDB'              => '0.07';
requires 'Catalyst::Plugin::Session::Store';
requires 'KiokuDB::Backend::BDB::GIN';

auto_install;
WriteAll;
