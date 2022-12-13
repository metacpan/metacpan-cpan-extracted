use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Create and manipulate volume widgets.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Curses-UI-Volume';
readme_from 'Volume.pm';
recursive_author_tests('xt');
requires 'Curses::UI' => 0;
requires 'Encode' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Curses-UI-Volume';
resources 'homepage' => 'https://github.com/tupinek/Curses-UI-Volume';
resources 'repository' => 'git://github.com/tupinek/Curses-UI-Volume';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
