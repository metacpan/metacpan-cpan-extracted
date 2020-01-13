use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Config utilitites.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Config-Utils';
readme_from 'Utils.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.09;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Config-Utils';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Config-Utils';
resources 'repository' => 'git://github.com/michal-josef-spacek/Config-Utils';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
