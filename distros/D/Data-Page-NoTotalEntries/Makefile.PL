use inc::Module::Install;
use Module::Install::AuthorTests;

name 'Data-Page-NoTotalEntries';
all_from 'lib/Data/Page/NoTotalEntries.pm';

requires 'Class::Accessor::Lite' => 0.05;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
