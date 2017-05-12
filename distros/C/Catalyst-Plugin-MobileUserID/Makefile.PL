use inc::Module::Install;
name 'Catalyst-Plugin-MobileUserID';
all_from 'lib/Catalyst/Plugin/MobileUserID.pm';

build_requires 'Test::More';
requires 'HTTP::MobileUserID' => 0.01;
use_test_base;
auto_install;
WriteAll;
