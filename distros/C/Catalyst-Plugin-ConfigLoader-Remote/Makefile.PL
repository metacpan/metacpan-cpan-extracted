use inc::Module::Install;

name 'Catalyst-Plugin-ConfigLoader-Remote';
all_from 'lib/Catalyst/Plugin/ConfigLoader/Remote.pm';

requires 'Catalyst::Plugin::ConfigLoader';
requires 'MRO::Compat';
requires 'File::Fetch';

auto_install;
WriteAll;
