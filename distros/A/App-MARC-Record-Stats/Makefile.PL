use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to work with MARC::Record::Stats on MARC dataset.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/marc-record-stats';
license 'bsd';
name 'App-MARC-Record-Stats';
perl_version 5.006;
readme_from 'bin/marc-record-stats';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
requires 'List::Util' => 1.33;
requires 'MARC::File::XML' => '1.0.4';
requires 'MARC::Record::Stats' => 0;
requires 'Readonly' => 0;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-MARC-Record-Stats/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-MARC-Record-Stats';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-MARC-Record-Stats';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
