use inc::Module::Install;
name 'Acme-CPANAuthors-GeekHouse';
license 'MIT';
all_from 'lib/Acme/CPANAuthors/GeekHouse.pm';

requires 'Acme::CPANAuthors';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
