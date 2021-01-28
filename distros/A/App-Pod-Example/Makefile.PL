use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class for pod_example script.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/pod-example';
license 'bsd';
name 'App-Pod-Example';
perl_version 5.006;
readme_from 'bin/pod-example';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'English' => 0;
requires 'Error::Pure' => 0.15;
requires 'File::Temp' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0.04;
requires 'Pod::Example' => 0.03;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Pod-Example/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Pod-Example';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Pod-Example';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'IO::CaptureOutput' => 0;
test_requires 'Readonly' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
test_requires 'Test::Warn' => 0;
tests_recursive;
version '0.19';

# Run.
WriteAll();
