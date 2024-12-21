use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class and script for parse and print MARC leader.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/marc-leader';
license 'bsd';
name 'App-MARC-Leader';
perl_version 5.006;
readme_from 'bin/marc-leader';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Getopt::Std' => 0;
requires 'MARC::File::XML' => '1.0.4';
requires 'MARC::Leader' => 0.05;
requires 'MARC::Leader::Print' => 0.04;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-MARC-Leader/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-MARC-Leader';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-MARC-Leader';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
