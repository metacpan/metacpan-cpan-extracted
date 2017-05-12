use inc::Module::Install;
name 'CGI-PSGI';
all_from 'lib/CGI/PSGI.pm';

requires 'CGI', '3.33';

build_requires 'Test::More', 0.88;
author_tests('xt');
auto_set_repository;
WriteAll;
