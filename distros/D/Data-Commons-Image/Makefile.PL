use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data object for Wikimedia Commons image.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-Commons-Image';
perl_version 5.008;
readme_from 'Image.pm';
recursive_author_tests('xt');
requires 'Data::Image' => 0.05;
requires 'Mo' => 0;
requires 'Mo::utils' => 0.26;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-Commons-Image/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-Commons-Image';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-Commons-Image';
test_requires 'DateTime' => 0;
test_requires 'Error::Pure' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
