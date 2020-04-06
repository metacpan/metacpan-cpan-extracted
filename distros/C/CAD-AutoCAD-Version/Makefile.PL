use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class which work with AutoCAD versions.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'CAD-AutoCAD-Version';
perl_version 5.006;
readme_from 'Version.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=CAD-AutoCAD-Version';
resources 'homepage' => 'https://github.com/michal-josef-spacek/CAD-AutoCAD-Version';
resources 'repository' => 'git://github.com/michal-josef-spacek/CAD-AutoCAD-Version';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
