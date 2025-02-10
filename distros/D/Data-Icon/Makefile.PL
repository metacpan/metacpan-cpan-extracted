use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data objects for icon.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-Icon';
perl_version 5.008;
readme_from 'Icon.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0;
requires 'Mo' => 0;
requires 'Mo::utils' => 0.05;
requires 'Mo::utils::CSS' => 0.03;
requires 'Mo::utils::URI' => 0.02;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-Icon/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-Icon';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-Icon';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
