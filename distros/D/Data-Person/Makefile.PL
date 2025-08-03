use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data objects for person.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-Person';
perl_version 5.008;
readme_from 'Person.pm';
recursive_author_tests('xt');
requires 'Mo' => 0;
requires 'Mo::utils' => 0.21;
requires 'Mo::utils::Array' => 0;
requires 'Mo::utils::Email' => 0;
requires 'Mo::utils::Number' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-Person/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-Person';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-Person';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Data::ExternalId' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
