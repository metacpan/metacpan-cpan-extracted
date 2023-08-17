use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'PYX optimization tool.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/pyx-optimization';
license 'bsd';
name 'App-PYX-Optimization';
readme_from 'bin/pyx-optimization';
recursive_author_tests('xt');
requires 'Getopt::Std' => 0;
requires 'PYX::Optimization' => 0.01;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-PYX-Optimization/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-PYX-Optimization';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-PYX-Optimization';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.07;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.04';

# Run.
WriteAll();
