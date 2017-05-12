# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Create and manipulate time widgets.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Curses-UI-Time';
readme_from 'Time.pm';
recursive_author_tests('xt');
requires 'Curses::UI' => 0;
requires 'Curses::UI::Number' => 0;
requires 'Encode' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Curses-UI-Time';
resources 'homepage' => 'https://github.com/tupinek/Curses-UI-Time';
resources 'repository' => 'git://github.com/tupinek/Curses-UI-Time';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
