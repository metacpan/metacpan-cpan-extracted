use inc::Module::Install;
name 'Catalyst-Plugin-FormValidator-Simple-Auto';
all_from 'lib/Catalyst/Plugin/FormValidator/Simple/Auto.pm';

build_requires 'Test::More';

requires 'Catalyst' => '5.80001';
requires 'Catalyst::Plugin::FormValidator::Simple';
requires 'FormValidator::Simple' => '0.20';
requires 'UNIVERSAL::isa';
requires 'YAML';

use_test_base;
auto_include;
WriteAll;
