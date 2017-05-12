use inc::Module::Install;
name 'Config-Pit';
all_from 'lib/Config/Pit.pm';

requires 'Path::Class';
requires 'File::Temp' => 0.20;
requires 'YAML::Syck' => 1.00;
requires 'File::HomeDir';
requires 'File::Spec';
requires 'List::MoreUtils';

install_script 'bin/ppit';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
