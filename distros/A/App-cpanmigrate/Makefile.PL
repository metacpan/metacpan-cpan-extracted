use inc::Module::Install;
name 'App-cpanmigrate';
all_from 'lib/App/cpanmigrate.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

install_script 'bin/cpanmigrate';

test_requires 'Test::More' => 0.98;
auto_set_repository;
auto_include;
WriteAll;
