use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool for ISBN checking.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/isbn-check';
license 'bsd';
name 'App-ISBN-Check';
perl_version 5.006;
readme_from 'bin/isbn-check';
recursive_author_tests('xt');
requires 'Business::ISBN' => 0;
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
requires 'Perl6::Slurp' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-ISBN-Check/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-ISBN-Check';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-ISBN-Check';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
