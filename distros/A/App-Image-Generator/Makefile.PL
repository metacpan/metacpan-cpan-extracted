use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Script to generate image.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/image-generator';
license 'bsd';
name 'App-Image-Generator';
readme_from 'bin/image-generator';
recursive_author_tests('xt');
requires 'English' => 0;
requires 'Error::Pure' => 0.16;
requires 'File::Basename' => 0;
requires 'Getopt::Std' => 0;
requires 'Image::Random' => 0.06;
requires 'Image::Select' => 0.03;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=App-Image-Generator';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Image-Generator';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Image-Generator';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
