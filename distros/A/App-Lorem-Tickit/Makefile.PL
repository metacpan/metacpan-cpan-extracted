use lib '.';
use strict;
use warnings;

use inc::Module::Install;

abstract 'Tickit application with lorem ipsum generator.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/lorem-tickit';
license 'bsd';
name 'App-Lorem-Tickit';
perl_version 5.006;
readme_from 'bin/lorem-tickit';
recursive_author_tests('xt');
requires 'Getopt::Std' => 0;
requires 'Text::Lorem' => 0;
requires 'Tickit' => 0;
requires 'Tickit::Pen' => 0;
requires 'Tickit::Widget' => 0;
requires 'Tickit::Widget::Choice' => 0;
requires 'Tickit::Widget::ScrollBox' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Lorem-Tickit/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Lorem-Tickit';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Lorem-Tickit';
test_requires 'English' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.01';

WriteAll();
