use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Fast Common Gateway Interface Class for CGI::Pure.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.01;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'CGI-Pure-Fast';
readme_from 'Fast.pm';
recursive_author_tests('xt');
requires 'CGI::Pure' => 0.01;
requires 'FCGI' => 0.77;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=CGI-Pure-Fast';
resources 'homepage' => 'https://github.com/tupinek/CGI-Pure-Fast';
resources 'repository' => 'git://github.com/tupinek/CGI-Pure-Fast';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
