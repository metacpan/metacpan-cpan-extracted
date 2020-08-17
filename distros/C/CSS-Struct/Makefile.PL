use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Struct oriented CSS manipulation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'CSS-Struct';
readme_from 'Struct.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.11;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=CSS-Struct';
resources 'homepage' => 'https://github.com/michal-josef-spacek/CSS-Struct';
resources 'repository' => 'git://github.com/michal-josef-spacek/CSS-Struct';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
