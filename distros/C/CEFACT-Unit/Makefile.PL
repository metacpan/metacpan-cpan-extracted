use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'CEFACT unit handling.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_share 'share';
license 'bsd';
name 'CEFACT-Unit';
perl_version 5.006002;
readme_from 'Unit.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Data::CEFACT::Unit' => 0;
requires 'File::Share' => 0;
requires 'IO::File' => 0;
requires 'List::Util' => 1.33;
requires 'Mo::utils' => 0.21;
requires 'Text::CSV_XS' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/CEFACT-Unit/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/CEFACT-Unit';
resources 'repository' => 'git://github.com/michal-josef-spacek/CEFACT-Unit';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
