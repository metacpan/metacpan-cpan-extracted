use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to parse and print MARC 008 field.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/marc-field008';
license 'bsd';
name 'App-MARC-Field008';
perl_version 5.006;
readme_from 'bin/marc-field008';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Getopt::Std' => 0;
requires 'MARC::File::XML' => '1.0.4';
requires 'MARC::Leader' => 0.06;
requires 'MARC::Field008' => 0;
requires 'MARC::Field008::Print' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-MARC-Field008/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-MARC-Field008';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-MARC-Field008';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
