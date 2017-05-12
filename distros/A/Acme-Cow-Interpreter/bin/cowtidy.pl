#!/usr/bin/perl
#
# cowtidy - pretty-prints Cow source code
#
# Author:      Peter John Acklam
# Time-stamp:  2010-03-22 20:37:11 +01:00
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

# Initialize option variables.

our $opt_n;
our $opt_s;
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
Cow source code pretty-printer.

  -n     use line numbering
  -s     separate different instructions by a blank line
  -h     print usage and exit
  -v     print version information and exit

If program file is omitted, code is read through the standard input.

Report bugs to <pjacklam\@online.no>.
EOF
}

###############################################################################
## Process command line options and arguments.
###############################################################################

Getopt::Std::getopts('nshv') or die <<"EOF";
For more information: $PROGNAME -h
EOF

print_usage,   exit if $opt_h;
print_version, exit if $opt_v;

###############################################################################
## This is where the real action begins.
###############################################################################

die "$PROGNAME: Too many input arguments" if @ARGV > 1;

unshift @ARGV, '-' unless @ARGV;

my $cmd_num = 0;

my $prev_cmd;

while (<>) {

    for my $cmd (/([Mm][Oo][Oo]|MMM|OO[MO]|oom)/g) {

        # Insert a blank line

        if ($opt_s and $. > 1 and $cmd ne $prev_cmd) {
            print "\n"
              or die "$PROGNAME: print failed: $!\n";
        }

        if ($opt_n) {
            printf "%7u ", $cmd_num
              or die "$PROGNAME: print failed: $!\n";
        }

        print "$cmd\n"
          or die "$PROGNAME: print failed: $!\n";

        $prev_cmd = $cmd;
        ++ $cmd_num;
    }

}

# Emacs Local Variables:
# Emacs coding: us-ascii-unix
# Emacs End:
