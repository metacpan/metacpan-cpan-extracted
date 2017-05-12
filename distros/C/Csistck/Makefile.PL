use strict;
use warnings;
use inc::Module::Install;

name 'Csistck';

perl_version '5.010';

version_from 'lib/Csistck.pm';
license_from 'lib/Csistck.pm';
author 'Anthony Johnson <aj@ohess.org>';

homepage 'http://ohess.org/projects/csistck';
bugtracker 'http://github.com/agjohnson/csistck/issues';
repository 'http://github.com/agjohnson/csistck.git';

requires 'Digest::MD5';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::stat';
requires 'Getopt::Long';
requires 'Sys::Hostname::Long';
requires 'Scalar::Util';
requires 'Template';
requires 'Term::ReadKey';
requires 'Text::Diff';
requires 'Test::Exception';

# This module fails on !Linux
if ("$^O" eq "linux") {
    requires 'Linux::Distribution' => '0.21';
}

WriteAll;
