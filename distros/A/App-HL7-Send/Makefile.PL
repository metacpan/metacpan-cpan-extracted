use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Distribution for hl7send script.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_script 'bin/hl7send';
license 'bsd';
name 'App-HL7-Send';
readme_from 'bin/hl7send';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.15;
requires 'Getopt::Std' => 0;
requires 'Net::HL7::Connection' => 0;
requires 'Net::HL7::Message' => 0;
requires 'Perl6::Slurp' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/App-HL7-Send/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/App-HL7-Send';
resources 'repository' => 'git://github.com/michal-josef-spacek/App-HL7-Send';
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
