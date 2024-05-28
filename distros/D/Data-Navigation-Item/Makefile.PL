use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data object for navigation item.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-Navigation-Item';
readme_from 'Item.pm';
recursive_author_tests('xt');
requires 'Mo' => 0;
requires 'Mo::utils' => 0.28;
requires 'Mo::utils::CSS' => 0.02;
requires 'Mo::utils::URI' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-Navigation-Item/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-Navigation-Item';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-Navigation-Item';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
