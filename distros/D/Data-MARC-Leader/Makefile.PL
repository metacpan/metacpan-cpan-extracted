use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data objects for MARC leader.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-MARC-Leader';
perl_version 5.008;
readme_from 'Leader.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Mo' => 0;
requires 'Mo::utils' => 0.22;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-MARC-Leader/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-MARC-Leader';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-MARC-Leader';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
