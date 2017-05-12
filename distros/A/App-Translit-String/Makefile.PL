# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Script to transliterate string.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/translit-string';
license 'bsd';
name 'App-Translit-String';
readme_from 'bin/translit-string';
recursive_author_tests('xt');
requires 'English' => 0;
requires 'Error::Pure' => 0.16;
requires 'Getopt::Std' => 0;
requires 'Lingua::Translit' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=App-Translit-String';
resources 'homepage' => 'https://github.com/tupinek/App-Translit-String';
resources 'repository' => 'git://github.com/tupinek/App-Translit-String';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
