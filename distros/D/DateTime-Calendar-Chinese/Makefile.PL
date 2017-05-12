use inc::Module::Install;

name 'DateTime-Calendar-Chinese';
all_from 'lib/DateTime/Calendar/Chinese.pm';

requires 'DateTime::Event::Chinese', '1.00';

auto_set_repository;
author_tests 'xt';
WriteAll;