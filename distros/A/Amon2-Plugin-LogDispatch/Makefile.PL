use inc::Module::Install;
use Module::Install::AuthorTests;

name 'Amon2-Plugin-LogDispatch';
all_from 'lib/Amon2/Plugin/LogDispatch.pm';

requires 'Log::Dispatch';
requires 'Amon2' => '2.33';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
