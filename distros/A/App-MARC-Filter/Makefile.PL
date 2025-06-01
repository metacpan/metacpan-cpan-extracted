use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to filter records in MARC dataset.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/marc-filter';
license 'bsd';
name 'App-MARC-Filter';
perl_version 5.006;
readme_from 'bin/marc-filter';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
requires 'List::Util' => 1.33;
requires 'MARC::Leader' => 0;
requires 'MARC::Leader::Utils' => 0;
requires 'MARC::File::XML' => '1.0.4';
requires 'Readonly' => 0;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-MARC-Filter/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-MARC-Filter';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-MARC-Filter';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.06';

# Run.
WriteAll();
