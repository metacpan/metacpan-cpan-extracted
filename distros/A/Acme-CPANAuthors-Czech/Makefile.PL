use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'We are Czech CPAN authors.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Acme-CPANAuthors-Czech';
perl_version 5.0100;
readme_from 'Czech.pm';
recursive_author_tests('xt');
requires 'Acme::CPANAuthors' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Acme-CPANAuthors-Czech/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Acme-CPANAuthors-Czech';
resources 'repository' => 'git://github.com/michal-josef-spacek/Acme-CPANAuthors-Czech';
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::More' => 0;
tests_recursive;
version '0.31';

# Run.
WriteAll();
