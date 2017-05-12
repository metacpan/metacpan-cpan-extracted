use inc::Module::Install;
name 'CPAN-Mini-Growl';
all_from 'lib/CPAN/Mini/Growl.pm';

requires 'CPAN::Mini';
requires 'Mac::Growl';
requires 'CPAN::DistnameInfo';
requires 'Parse::CPAN::Authors';
requires 'LWP::Simple';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
