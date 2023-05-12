use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Distribution for hl7dump script.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/hl7dump';
license 'bsd';
name 'App-HL7-Dump';
perl_version 5.006;
readme_from 'bin/hl7dump';
recommends 'Term::ANSIColor' => 5.01;
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'English' => 0;
requires 'Error::Pure' => 0.15;
requires 'Getopt::Std' => 0;
requires 'Net::HL7::Message' => 0;
requires 'Perl6::Slurp' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-HL7-Dump/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-HL7-Dump';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-HL7-Dump';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
