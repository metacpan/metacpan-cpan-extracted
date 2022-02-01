use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class and script for getting of dist from CPAN.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/cpan-get';
license 'bsd';
name 'App-CPAN-Get';
perl_version 5.006;
readme_from 'bin/cpan-get';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'Exporter' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0;
requires 'LWP::UserAgent' => 0;
requires 'Menlo::Index::MetaCPAN' => 0;
requires 'Readonly' => 0;
requires 'URI::cpan' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-CPAN-Get/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-CPAN-Get';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-CPAN-Get';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::LWP::UserAgent' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
