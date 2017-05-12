use inc::Module::Install;
name 'DateTime-Span-Birthdate';
all_from 'lib/DateTime/Span/Birthdate.pm';

requires 'DateTime';
requires 'DateTime::Span';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
