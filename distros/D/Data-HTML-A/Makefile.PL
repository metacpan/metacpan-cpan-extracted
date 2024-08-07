use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data object for HTML a element.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-HTML-A';
perl_version 5.008;
readme_from 'A.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0;
requires 'List::Util' => 0;
requires 'Mo' => 0;
requires 'Mo::utils' => 0.14;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-HTML-A/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-HTML-A';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-HTML-A';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Tags::Output::Raw' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
