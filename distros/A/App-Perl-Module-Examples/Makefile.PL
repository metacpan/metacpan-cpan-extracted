use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool for creating examples from Perl module POD documentation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/perl-module-examples';
license 'bsd';
name 'App-Perl-Module-Examples';
perl_version 5.006;
readme_from 'bin/perl-module-examples';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'File::Find::Rule' => 0;
requires 'File::Spec::Functions' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0;
requires 'Pod::Example' => 0.12;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Perl-Module-Examples/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Perl-Module-Examples';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Perl-Module-Examples';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
