use inc::Module::Install;
name 'Acme-NabeAtzz';
all_from 'lib/Acme/NabeAtzz.pm';

requires 'XSLoader';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
