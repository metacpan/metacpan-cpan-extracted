# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Base class for pod_example script.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/pod-example';
license 'bsd';
name 'App-Pod-Example';
readme_from 'bin/pod-example';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'English' => 0;
requires 'Error::Pure' => 0.15;
requires 'File::Temp' => 0;
requires 'IO::Barf' => 0.04;
requires 'Pod::Example' => 0.03;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=App-Pod-Example';
resources 'homepage' => 'https://github.com/tupinek/App-Pod-Example';
resources 'repository' => 'git://github.com/tupinek/App-Pod-Example';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'IO::CaptureOutput' => 0;
test_requires 'Readonly' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
test_requires 'Test::Warn' => 0;
tests_recursive;
version '0.16';

# Run.
WriteAll();
