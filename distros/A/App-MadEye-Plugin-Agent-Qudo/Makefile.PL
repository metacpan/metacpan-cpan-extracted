use inc::Module::Install;
name 'App-MadEye-Plugin-Agent-Qudo';
all_from 'lib/App/MadEye/Plugin/Agent/Qudo.pm';

requires 'App::MadEye';
requires 'Qudo';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
