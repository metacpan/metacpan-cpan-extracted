use inc::Module::Install;
name 'Acme-Acotie';
all_from 'lib/Acme/Acotie.pm';

requires 'Class::Inspector';
requires 'List::Util';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
