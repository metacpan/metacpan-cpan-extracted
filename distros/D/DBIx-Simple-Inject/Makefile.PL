use inc::Module::Install;
all_from 'lib/DBIx/Simple/Inject.pm';
readme_from;

requires 'Class::Load';
requires 'DBI';
requires 'DBIx::Simple';
requires 'SQL::Abstract'; # because lvalue sucks. you can change "abstract" class
requires 'Scalar::Util';
requires 'parent';

test_requires 'Test::More' => 0.96; # subtest/done_testing
test_requires 'Test::Requires';
auto_include_deps;

tests_recursive;

repository 'http://github.com/tomi-ru/DBIx-Simple-Inject';
bugtracker 'http://github.com/tomi-ru/DBIx-Simple-Inject/issues';

WriteAll;
