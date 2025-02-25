use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to fetch module from CPAN archive.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/cpan-get';
license 'bsd';
name 'App-CPAN-Get';
perl_version 5.006;
readme_from 'bin/cpan-get';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Cpanel::JSON::XS' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Exporter' => 0;
requires 'File::Spec::Functions' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0;
requires 'LWP::UserAgent' => 0;
requires 'Readonly' => 0;
requires 'Scalar::Util' => 0;
requires 'URI' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-CPAN-Get/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-CPAN-Get';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-CPAN-Get';
test_requires 'Cwd' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Temp' => 0;
test_requires 'HTTP::Response' => 0;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::LWP::UserAgent' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.14';

# Run.
WriteAll();
