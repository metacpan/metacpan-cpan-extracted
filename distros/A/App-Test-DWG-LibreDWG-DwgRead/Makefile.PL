use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Application to test DWG files by LibreDWG dwgread command.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/test-dwg-libredwg-dwgread';
license 'bsd';
name 'App-Test-DWG-LibreDWG-DwgRead';
perl_version 5.006;
readme_from 'bin/test-dwg-libredwg-dwgread';
recursive_author_tests('xt');
requires 'Capture::Tiny' => 0;
requires 'File::Copy' => 0;
requires 'File::Find::Rule' => 0;
requires 'File::Find::Rule::DWG' => 0;
requires 'File::Path' => 0;
requires 'File::Spec::Functions' => 0;
requires 'File::Temp' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Test-DWG-LibreDWG-DwgRead/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Test-DWG-LibreDWG-DwgRead';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Test-DWG-LibreDWG-DwgRead';
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
