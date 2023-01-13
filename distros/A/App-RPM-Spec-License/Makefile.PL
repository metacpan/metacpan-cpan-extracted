use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tool for working with RPM spec file licenses.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/rpm-spec-license';
license 'bsd';
name 'App-RPM-Spec-License';
perl_version 5.006;
readme_from 'bin/rpm-spec-license';
recursive_author_tests('xt');
requires 'English' => 0;
requires 'Error::Pure' => 0.30;
requires 'File::Find::Rule' => 0;
requires 'Getopt::Std' => 0;
requires 'List::Util' => 1.33;
requires 'Parse::RPM::Spec' => 'v1.1.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-RPM-Spec-License/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-RPM-Spec-License';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-RPM-Spec-License';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
