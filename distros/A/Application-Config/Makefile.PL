use inc::Module::Install;

name 'Application-Config';
all_from 'lib/Application/Config.pm';
license 'MIT';

requires 'Config::Tiny' => 0;
requires 'File::HomeDir' => 0;

auto_install;
WriteAll;
