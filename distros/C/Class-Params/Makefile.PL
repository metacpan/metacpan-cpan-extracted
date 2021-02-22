use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Parameter utils for constructor.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Class-Params';
readme_from 'Params.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.16;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'Scalar::Util' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Class-Params/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Class-Params';
resources 'repository' => 'git://github.com/michal-josef-spacek/Class-Params';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
