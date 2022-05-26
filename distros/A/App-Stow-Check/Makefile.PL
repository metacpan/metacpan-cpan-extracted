use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Distribution for stow-check script.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/stow-check';
license 'bsd';
name 'App-Stow-Check';
perl_version 5.006;
readme_from 'bin/stow-check';
recursive_author_tests('xt');
requires 'Cwd' => 0;
requires 'File::Spec::Functions' => 0;
requires 'File::Which' => 0;
requires 'Getopt::Std' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-Stow-Check/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-Stow-Check';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-Stow-Check';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::LWP::UserAgent' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
