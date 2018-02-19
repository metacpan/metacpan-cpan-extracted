use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Module for simple configure file parsing.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Config-Dot';
readme_from 'Dot.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Config::Utils' => 0.03;
requires 'Error::Pure' => 0.16;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Config-Dot';
resources 'homepage' => 'https://github.com/tupinek/Config-Dot';
resources 'repository' => 'git://github.com/tupinek/Config-Dot';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.16;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
