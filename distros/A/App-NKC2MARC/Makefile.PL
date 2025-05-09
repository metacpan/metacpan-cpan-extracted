use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool to fetch record from National library of the Czech Republic to MARC file.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/nkc-to-marc';
license 'bsd';
name 'App-NKC2MARC';
perl_version 5.006;
readme_from 'bin/nkc-to-marc';
recursive_author_tests('xt');
requires 'Encode' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Getopt::Std' => 0;
requires 'IO::Barf' => 0;
requires 'List::Util' => 1.33;
requires 'MARC::File::XML' => 0;
requires 'MARC::Record' => 0;
requires 'Readonly' => 0;
requires 'ZOOM' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-NKC2MARC/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-NKC2MARC';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-NKC2MARC';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
test_requires 'Test::Warn' => 0.31;
tests_recursive;
version '0.03';

# Run.
WriteAll();
