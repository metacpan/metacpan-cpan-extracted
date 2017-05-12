use inc::Module::Install;
name 'Acme-FizzBuzz';
all_from 'lib/Acme/FizzBuzz.pm';
readme_from 'lib/Acme/FizzBuzz.pm';
readme_markdown_from 'lib/Acme/FizzBuzz.pm';
githubmeta;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
WriteAll;
