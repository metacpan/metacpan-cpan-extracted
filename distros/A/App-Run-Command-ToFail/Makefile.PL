use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to run command in cycle to check fail.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/run-command-to-fail';
license 'bsd';
name 'App-Run-Command-ToFail';
perl_version 5.006;
readme_from 'bin/run-command-to-fail';
recursive_author_tests('xt');
requires 'Getopt::Std' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Run-Command-ToFail/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Run-Command-ToFail';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Run-Command-ToFail';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'File::Temp' => 0;
test_requires 'IO::Barf' => 0;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.05';

# Run.
WriteAll();
