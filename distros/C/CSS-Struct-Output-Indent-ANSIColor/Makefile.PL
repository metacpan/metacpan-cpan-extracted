use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Indent printing \'CSS::Struct\' structure to CSS code with ansi color output.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'CSS-Struct-Output-Indent-ANSIColor';
readme_from 'ANSIColor.pm';
recursive_author_tests('xt');
requires 'CSS::Struct::Output::Indent' => 0.01;
requires 'Indent' => 0.01;
requires 'Readonly' => 0;
requires 'Term::ANSIColor' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/CSS-Struct-Output-Indent-ANSIColor/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/'.
	'CSS-Struct-Output-Indent-ANSIColor';
resources 'repository' => 'git://github.com/michal-josef-spacek/'.
	'CSS-Struct-Output-Indent-ANSIColor';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
