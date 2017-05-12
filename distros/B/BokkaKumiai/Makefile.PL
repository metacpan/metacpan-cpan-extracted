use inc::Module::Install;
name 'BokkaKumiai';
all_from 'lib/BokkaKumiai.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
