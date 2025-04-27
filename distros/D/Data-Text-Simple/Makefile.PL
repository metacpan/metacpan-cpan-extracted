use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data objects for text in language.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-Text-Simple';
perl_version 5.008;
readme_from 'Simple.pm';
recursive_author_tests('xt');
requires 'Mo' => 0;
requires 'Mo::utils' => 0;
requires 'Mo::utils::Language' => 0.05;
requires 'Mo::utils::Number' => 0;
resources 'bugtracker' => 'https://github.com/commons-vote/Data-Text-Simple/issues';
resources 'homepage' => 'https://github.com/commons-vote/Data-Text-Simple';
resources 'repository' => 'git://github.com/commons-vote/Data-Text-Simple';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
