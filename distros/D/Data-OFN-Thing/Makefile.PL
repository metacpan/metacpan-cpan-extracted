use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Data objects for OFN thing.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Data-OFN-Thing';
perl_version 5.008;
readme_from 'Thing.pm';
recursive_author_tests('xt');
requires 'Mo' => 0;
requires 'Mo::utils' => 0.08;
requires 'Mo::utils::Array' => 0;
requires 'Mo::utils::IRI' => 0.02;
requires 'Mo::utils::Number' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Data-OFN-Thing/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Data-OFN-Thing';
resources 'repository' => 'git://github.com/michal-josef-spacek/Data-OFN-Thing';
test_requires 'Data::OFN::Common::TimeMoment' => 0;
test_requires 'Data::Text::Simple' => 0;
test_requires 'DateTime' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
