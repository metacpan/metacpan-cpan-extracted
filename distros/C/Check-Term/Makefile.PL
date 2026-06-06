use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Check terminal functionality.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Check-Term';
readme_from 'Term.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'Term::Terminfo' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Check-Term/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Check-Term';
resources 'repository' => 'git://github.com/michal-josef-spacek/Check-Term';
test_requires 'Term::Terminfo' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
