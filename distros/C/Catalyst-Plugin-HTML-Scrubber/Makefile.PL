use inc::Module::Install;
name 'Catalyst-Plugin-HTML-Scrubber';
all_from 'lib/Catalyst/Plugin/HTML/Scrubber.pm';

requires 'Catalyst::Runtime' => '5.71001';
requires 'HTML::Scrubber';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.88';
auto_set_repository;
auto_include;
WriteAll;
