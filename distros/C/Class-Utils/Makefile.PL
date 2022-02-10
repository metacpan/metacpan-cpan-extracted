use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class utilities.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'Cwd' => 0;
author_requires 'English' => 0;
author_requires 'File::Spec::Functions' => 0;
author_requires 'FindBin' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Class-Utils';
perl_version 5.008;
readme_from 'Utils.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.09,
requires 'Exporter' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Class-Utils/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Class-Utils';
resources 'repository' => 'git://github.com/michal-josef-spacek/Class-Utils';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.11';

# Run.
WriteAll();
