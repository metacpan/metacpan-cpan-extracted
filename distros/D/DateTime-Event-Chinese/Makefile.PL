use inc::Module::Install;

name 'DateTime-Event-Chinese';
all_from 'lib/DateTime/Event/Chinese.pm';
requires 'DateTime::Astro';
requires 'Math::Round';

author_tests 'xt';
auto_set_repository;

WriteAll;