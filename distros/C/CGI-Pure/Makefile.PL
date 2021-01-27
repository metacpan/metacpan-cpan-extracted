use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Common Gateway Interface Class.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'CGI-Pure';
readme_from 'Pure.pm';
recursive_author_tests('xt');
requires 'CGI::Deurl::XS' => 0;
requires 'Class::Utils' => 0.02;
requires 'Encode' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0.16;
requires 'IO::File' => 0;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'URI::Escape' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/CGI-Pure/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/CGI-Pure';
resources 'repository' => 'git://github.com/michal-josef-spacek/CGI-Pure';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.16;
test_requires 'File::Object' => 0.03;
test_requires 'IO::Scalar' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.09';

# Run.
WriteAll();
