use inc::Module::Install;
name 'Data-Lotter';
all_from 'lib/Data/Lotter.pm';
requires 'Class::Accessor::Fast';
build_requires 'Test::More';
use_test_base;
auto_install;
WriteAll;
