use inc::Module::Install;
name 'Catalyst-Plugin-FormValidator-Simple-Messages';
all_from 'lib/Catalyst/Plugin/FormValidator/Simple/Messages.pm';

build_requires 'Test::More';

requires 'Catalyst' => '5.30';
requires 'Catalyst::Plugin::FormValidator::Simple' => '0.12';
requires 'YAML' => '0';

use_test_base;
auto_install;
WriteAll;
