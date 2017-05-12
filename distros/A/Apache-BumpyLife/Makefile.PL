use inc::Module::Install;
name 'Apache-BumpyLife';
all_from 'lib/Apache/BumpyLife.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
requires 'Apache';

auto_set_repository;
#auto_include;
WriteAll;
