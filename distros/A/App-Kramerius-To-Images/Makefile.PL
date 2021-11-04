use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Base class and script for creating Kramerius downloader.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/kramerius2images';
license 'bsd';
name 'App-Kramerius-To-Images';
perl_version 5.006;
readme_from 'bin/kramerius2images';
recursive_author_tests('xt');
requires 'App::Kramerius::V4';
requires 'Class::Utils' => 0;
requires 'Data::Kramerius' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
requires 'HTTP::Request' => 0;
requires 'IO::Barf' => 0;
requires 'JSON::XS' => 0;
requires 'LWP::UserAgent' => 6;
requires 'METS::Files' => 0;
requires 'Perl6::Slurp' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Kramerius-To-Images/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Kramerius-To-Images';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Kramerius-To-Images';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
