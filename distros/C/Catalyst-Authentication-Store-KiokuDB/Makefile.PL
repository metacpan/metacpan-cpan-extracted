use inc::Module::Install;

name 'Catalyst-Authentication-Store-KiokuDB';
all_from 'lib/Catalyst/Authentication/Store/KiokuDB.pm';

requires 'KiokuDB'              => '0.07';
requires 'Catalyst::Plugin::Authentication';
requires 'KiokuDB::Backend::BDB::GIN';

auto_install;
WriteAll;
