use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class for pyx2xml application.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/pyx2xml';
license 'bsd';
name 'App-PYX2XML';
readme_from 'bin/pyx2xml';
recursive_author_tests('xt');
requires 'Getopt::Std' => 0;
requires 'PYX::SGML::Tags' => 0.02;
requires 'Tags::Output::Indent' => 0.04;
requires 'Tags::Output::Raw' => 0.04;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=App-PYX2XML';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-PYX2XML';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-PYX2XML';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'Unicode::UTF8' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
