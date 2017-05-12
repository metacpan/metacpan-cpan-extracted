use inc::Module::Install;

requires Catalyst               => '5.00';
requires 'Class::C3'            => 0.14;
requires 'WebService::YouTube'  => 0;

name 'Catalyst-Model-YouTube';
all_from 'lib/Catalyst/Model/YouTube.pm';

auto_install;
WriteAll;

