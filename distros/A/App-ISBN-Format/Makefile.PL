use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class and script for ISBN formatting.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/isbn-format';
license 'bsd';
name 'App-ISBN-Format';
perl_version 5.006;
readme_from 'bin/isbn-format';
recursive_author_tests('xt');
requires 'Business::ISBN' => 0;
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-ISBN-Format/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-ISBN-Format';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-ISBN-Format';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
