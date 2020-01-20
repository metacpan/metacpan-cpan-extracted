use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Distribution for unicode-block script.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/unicode-block';
license 'bsd';
name 'App-Unicode-Block';
readme_from 'bin/unicode-block';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Curses::UI' => 0;
requires 'Encode' => 0;
requires 'Error::Pure' => 0.15;
requires 'Getopt::Std' => 0;
requires 'List::MoreUtils' => 0;
requires 'Unicode::Block::Ascii' => 0;
requires 'Unicode::Block::List' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=App-Unicode-Block';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Unicode-Block';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Unicode-Block';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
