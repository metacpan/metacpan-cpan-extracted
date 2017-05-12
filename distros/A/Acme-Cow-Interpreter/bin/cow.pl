#!/usr/bin/perl
#
# cow - Cow programming language interpreter
#
# This interpreter can be used to process Cow source files, e.g., with
#
#    cow source.cow
#
# If your operating system allows scripts on the `#!' line, you can copy this
# program to, e.g., `/usr/local/bin/cow' and then use `#!/usr/local/bin/cow' on
# the top of your Cow programs. Then you don't need to call this interpreter
# explicitly.
#
# If your operating system does not allow scripts on the `#!' line, you can
# copy this file to, e.g., /usr/local/bin/cow.pl', compile the C wrapper
# `cow.c' (see the comments in the file header), copy the resulting executable
# file to `/usr/local/bin/cow', and then use `#!/usr/local/bin/cow' on the top
# of your Cow programs. Then you don't need to call this interpreter
# explicitly.
#
# Author:      Peter John Acklam
# Time-stamp:  2010-05-26 12:59:32 +02:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

###############################################################################
## Modules and package variables.
###############################################################################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings

use File::Basename ();  # split a pathname into pieces
use Getopt::Std ();     # process single-character command line options

use Acme::Cow::Interpreter ();

# Initialize option variables.

our $opt_h;
our $opt_v;

###############################################################################
## File-private lexical variables.
###############################################################################

my $VERSION  = '0.001';                         # program version
my $PROGNAME = File::Basename::basename($0);    # program name

###############################################################################
## Subroutines.
###############################################################################

###############################################################################
# print_version
#
# Print program version and copyright information.
#
sub print_version () {
    print <<"EOF" or die "$PROGNAME: print failed: $!\n";

$PROGNAME $VERSION

Copyright 2007-2010 Peter John Acklam.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

EOF
}

###############################################################################
# print_usage
#
# Print program usage.
#
sub print_usage () {
    print <<"EOF" or die "$PROGNAME: print failed: $!\n";
Usage: $PROGNAME [programfile]
Cow programming language interpreter.

  -h     print usage and exit
  -v     print version information and exit

If program file is omitted, code is read through the standard input.

Report bugs to <pjacklam\@online.no>.
EOF
}

###############################################################################
## Process command line options and arguments.
###############################################################################

Getopt::Std::getopts('hv') or die <<"EOF";
For more information: $PROGNAME -h
EOF

print_usage,   exit if $opt_h;
print_version, exit if $opt_v;

###############################################################################
## This is where the real action begins.
###############################################################################

die "$PROGNAME: Too many input arguments" if @ARGV > 1;

unshift @ARGV, '-' unless @ARGV;
my $file = shift;

my $cow = Acme::Cow::Interpreter -> new();
$cow -> parse_file($file);
#$cow -> dump_obj();
$cow -> execute();

# Emacs Local Variables:
# Emacs coding: us-ascii-unix
# Emacs End:
