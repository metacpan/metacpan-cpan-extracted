use inc::Module::Install;
name 'Chart-Timecard';
all_from 'lib/Chart/Timecard.pm';

requires
    'DateTime'     => 0.70,
    'Object::Tiny' => 1.08;

build_requires
    'Test::Cukes' => '0.10',
    'Test::More'  => '0.98';

tests 't/*.t';
author_tests 'xt';

auto_include;
auto_set_repository;
WriteAll;
