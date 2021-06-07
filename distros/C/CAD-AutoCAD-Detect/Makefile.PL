use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Detect AutoCAD files through magic string.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'CAD-AutoCAD-Detect';
requires 'CAD::AutoCAD::Version' => 0;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
readme_from 'Detect.pm';
recursive_author_tests('xt');
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=CAD-AutoCAD-Detect';
resources 'homepage' => 'https://github.com/michal-josef-spacek/CAD-AutoCAD-Detect';
resources 'repository' => 'git://github.com/michal-josef-spacek/CAD-AutoCAD-Detect';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
