use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'PDF DateTime Parser and Formatter.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'DateTime-Format-PDF';
perl_version 5.006002;
readme_from 'PDF.pm';
recursive_author_tests('xt');
requires 'DateTime::Format::Builder' => 0;
requires 'Error::Pure' => 0;
requires 'Scalar::Util' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/DateTime-Format-PDF/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/DateTime-Format-PDF';
resources 'repository' => 'git://github.com/michal-josef-spacek/DateTime-Format-PDF';
test_requires 'DateTime' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
