use inc::Module::Install;
name 'Catalyst-Plugin-DoCoMoUID';
all_from 'lib/Catalyst/Plugin/DoCoMoUID.pm';

build_requires 'Test::More';
use_test_base;
auto_install;
WriteAll;
