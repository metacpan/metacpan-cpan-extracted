use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data object for image.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-Image';
perl_version 5.008;
readme_from 'Image.pm';
recursive_author_tests('xt');
requires 'Mo' => 0;
requires 'Mo::utils' => 0.28;
requires 'Mo::utils::URI' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-Image/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-Image';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-Image';
test_requires 'DateTime' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
