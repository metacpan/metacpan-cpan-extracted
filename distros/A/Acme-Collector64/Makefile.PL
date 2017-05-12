use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'Acme-Collector64';
all_from 'lib/Acme/Collector64.pm';

test_requires 'Test::More' => 0.98;

tests 't/*.t';
author_tests('xt');

auto_set_repository;

WriteAll;
