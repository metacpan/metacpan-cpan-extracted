use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Utilities for CPAN::Changes.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'CPAN-Changes-Utils';
readme_from 'Utils.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'List::Util' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/CPAN-Changes-Utils/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/CPAN-Changes-Utils';
resources 'repository' => 'git://github.com/michal-josef-spacek/CPAN-Changes-Utils';
test_requires 'CPAN::Changes' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
