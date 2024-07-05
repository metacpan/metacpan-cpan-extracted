use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Generate random person.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-Random-Person';
perl_version 5.008;
readme_from 'Person.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Data::Person' => 0.02;
requires 'Error::Pure' => 0;
requires 'List::Util' => 1.33;
requires 'Mo::utils' => 0.06;
requires 'Mock::Person::CZ' => 0;
requires 'Scalar::Util' => 0;
requires 'Text::Unidecode' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-Random-Person/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-Random-Person';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-Random-Person';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
