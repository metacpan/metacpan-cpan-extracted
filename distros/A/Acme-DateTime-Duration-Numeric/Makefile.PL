use inc::Module::Install;
name 'Acme-DateTime-Duration-Numeric';
all_from 'lib/Acme/DateTime/Duration/Numeric.pm';

requires 'DateTime';
requires 'DateTime::Duration';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
