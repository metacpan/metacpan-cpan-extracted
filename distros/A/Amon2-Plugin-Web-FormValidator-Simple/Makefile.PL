use inc::Module::Install;
name 'Amon2-Plugin-Web-FormValidator-Simple';
all_from 'lib/Amon2/Plugin/Web/FormValidator/Simple.pm';
readme_from 'lib/Amon2/Plugin/Web/FormValidator/Simple.pm';
readme_markdown_from 'lib/Amon2/Plugin/Web/FormValidator/Simple.pm';
readme_pod_from 'lib/Amon2/Plugin/Web/FormValidator/Simple.pm';
githubmeta;

requires 'Amon2::Web';
requires 'FormValidator::Simple';

test_requires 'Test::WWW::Mechanize::PSGI';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
