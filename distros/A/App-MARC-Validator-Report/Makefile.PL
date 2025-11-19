use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to process MARC validation report.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/marc-validator-report';
license 'bsd';
name 'App-MARC-Validator-Report';
perl_version 5.006;
readme_from 'bin/marc-validator-report';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Cpanel::JSON::XS' => 0;
requires 'Getopt::Std' => 0;
requires 'Perl6::Slurp' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-MARC-Validator-Report/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-MARC-Validator-Report';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-MARC-Validator-Report';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.03';

# Run.
WriteAll();
