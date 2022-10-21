use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Script for Schema data manipulation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/schema-data';
license 'bsd';
name 'App-Schema-Data';
perl_version 5.006;
readme_from 'bin/schema-data';
recursive_author_tests('xt');
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Schema-Data/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Schema-Data';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Schema-Data';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.04';

# Run.
WriteAll();
