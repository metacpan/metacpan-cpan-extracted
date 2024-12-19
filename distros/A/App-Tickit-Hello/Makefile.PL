use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tickit application with hello world.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/tickit-hello';
license 'bsd';
name 'App-Tickit-Hello';
perl_version 5.006;
readme_from 'bin/tickit-hello';
recursive_author_tests('xt');
requires 'Getopt::Std' => 0;
requires 'List::Util' => 1.33;
requires 'Readonly' => 0;
requires 'Tickit' => 0;
requires 'Tickit::Widget::Static' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Tickit-Hello/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Tickit-Hello';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Tickit-Hello';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.01';

# Run.
WriteAll();
