use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to get MARC leader of field/subfield unique list.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/marc-list';
license 'bsd';
name 'App-MARC-List';
perl_version 5.006;
readme_from 'bin/marc-list';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
requires 'List::MoreUtils' => 0;
requires 'List::Util' => 0;
requires 'MARC::File::XML' => '1.0.4';
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-MARC-List/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-MARC-List';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-MARC-List';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
