use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Common data objects for OFN.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-OFN-Common';
perl_version 5.008;
readme_from 'Common.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0;
requires 'Mo' => 0;
requires 'Mo::utils' => 0.08;
requires 'Mo::utils::CEFACT' => 0.02;
requires 'Mo::utils::Number' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-OFN-Common/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-OFN-Common';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-OFN-Common';
test_requires 'DateTime' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
