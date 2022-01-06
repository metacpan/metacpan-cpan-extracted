use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class and script for composing DjVu files from images.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/images2djvu';
license 'bsd';
name 'App-Images-To-DjVu';
perl_version 5.006;
readme_from 'bin/images2djvu';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'File::Basename' => 0;
requires 'Getopt::Std' => 0;
requires 'Perl6::Slurp' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Images-To-DjVu/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Images-To-DjVu';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Images-To-DjVu';
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
