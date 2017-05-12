# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Create and manipulate number widgets.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Curses-UI-Number';
requires 'Curses::UI' => 0;
requires 'Encode' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
readme_from 'Number.pm';
recursive_author_tests('xt');
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Curses-UI-Number';
resources 'homepage' => 'https://github.com/tupinek/Curses-UI-Number';
resources 'repository' => 'git://github.com/tupinek/Curses-UI-Number';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
