#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Std;
use Convert::EDS::XDD qw(eds2xdd_string);

$Getopt::Std::STANDARD_HELP_VERSION = 1;

getopts '', \my %opts;

local $/;
while (<>) {
    print eds2xdd_string $_;
}

sub VERSION_MESSAGE() { print "eds2xdd $Convert::EDS::XDD::VERSION\n"; }
sub HELP_MESSAGE() {
print <<"EOT"
Usage: $0 [eds_file]
       echo 'eds_content' | $0

Opens files passed as arguments and writes them to stdout as XDD.
If there are no arguments, stdin is read
EOT
}

