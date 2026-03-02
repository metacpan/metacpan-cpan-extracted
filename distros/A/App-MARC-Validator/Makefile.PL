use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'MARC validator tool.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/marc-validator';
license 'bsd';
name 'App-MARC-Validator';
perl_version 5.006;
readme_from 'bin/marc-validator';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Cpanel::JSON::XS' => 0;
requires 'Data::MARC::Validator::Report' => 0.02;
requires 'DateTime' => 0;
requires 'English' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0;
requires 'MARC::File::XML' => '1.0.4';
requires 'MARC::Validator' => 0.11;
requires 'MARC::Validator::Filter' => 0;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-MARC-Validator/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-MARC-Validator';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-MARC-Validator';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.06';

# Run.
WriteAll();
