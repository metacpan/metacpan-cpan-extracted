use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool for update copyright years in Perl distribution.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/perl-module-copyright-years';
license 'bsd';
name 'App-Perl-Module-CopyrightYears';
perl_version 5.006;
readme_from 'bin/perl-module-copyright-years';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'File::Find::Rule' => 0;
requires 'File::Spec::Functions' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0;
requires 'Pod::CopyrightYears' => 0.03;
requires 'Perl6::Slurp' => 0;
requires 'String::UpdateYears' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Perl-Module-CopyrightYears/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Perl-Module-CopyrightYears';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Perl-Module-CopyrightYears';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
