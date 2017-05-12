use inc::Module::Install;
name 'App-cpanbaker';
all_from 'lib/App/cpanbaker.pm';

requires 'Getopt::Long';
requires 'List::MoreUtils';
requires 'File::Find::Rule';
requires 'File::Spec';
requires 'Log::Dispatch';
requires 'Pod::Simple::Text';
requires 'DateTime';
requires 'ExtUtils::Installed';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;

install_script 'bin/cpanbaker';

# readme_markdown_from 'lib/App/cpanbaker.pm';
readme_markdown_from 'bin/cpanbaker';

WriteAll;
