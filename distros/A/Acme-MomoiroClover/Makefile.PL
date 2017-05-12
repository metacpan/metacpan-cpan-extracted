use inc::Module::Install;

name     'Acme-MomoiroClover';
author   'Yuichi Tateno, <hotchpotch@gmail.com>';
license  'MIT';
all_from 'lib/Acme/MomoiroClover.pm';

requires 'Class::Accessor';
requires 'Date::Simple';
requires 'Test::Exception';

author_tests   'xt';
auto_set_repository;
auto_include_deps;
WriteAll;
