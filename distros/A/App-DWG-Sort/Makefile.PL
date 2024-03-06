use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to sort DWG files by version.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/dwg-sort';
license 'bsd';
name 'App-DWG-Sort';
perl_version 5.006;
readme_from 'bin/dwg-sort';
recursive_author_tests('xt');
requires 'CAD::AutoCAD::Detect' => 0.02;
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'File::Copy' => 0;
requires 'File::Find::Rule' => 0;
requires 'File::Find::Rule::DWG' => 0;
requires 'File::Path' => 0;
requires 'File::Spec::Functions' => 0;
requires 'Getopt::Std' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-DWG-Sort/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-DWG-Sort';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-DWG-Sort';
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
