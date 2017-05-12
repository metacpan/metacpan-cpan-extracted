#!/usr/bin/perl
#
# text2cow - prints Cow source code that prints a given text
#
# Author:      Peter John Acklam
# Time-stamp:  2010-05-26 14:18:31 +02:00
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

our $opt_h;
our $opt_v;

###############################################################################
## File-private lexical variables.
###############################################################################

my $VERSION  = '0.001';                         # program version
my $PROGNAME = File::Basename::basename($0);    # program name

my $ncmd_on_line = 0;   # number of command written on current line

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
Prints Cow source code that, when executed, prints a given text.

  -h     print usage and exit
  -v     print version information and exit

If file is omitted, text is read through the standard input.

Example: \$ printf 'Hello, World!\\n' | $PROGNAME > hello.cow
         \$ cow hello.cow
         Hello, World!

Report bugs to <pjacklam\@online.no>.
EOF
}

###############################################################################
# output COMMAND
#
# Prints a COMMAND to the standard output.

sub output {
    my $cmd = shift;
    if ($ncmd_on_line == 20) {
        print "\n" or die "$PROGNAME: print failed: $!\n";
        $ncmd_on_line = 0;
    } elsif ($ncmd_on_line > 0) {
        print " " or die "$PROGNAME: print failed: $!\n";
    }
    print $cmd or die "$PROGNAME: print failed: $!\n";
    ++ $ncmd_on_line;
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

local $/ = undef;       # file slurp mode
my $text = <>;          # get input text string

die "$PROGNAME: No input" unless defined $text;

my $n = length $text;   # get the number of characters in the string
my $prev_ord;           # this variable holds the previous ordinal value

for (my $i = 0 ; $i < $n ; ++ $i) {

    my $chr = substr($text, $i, 1);     # get this character ...
    my $ord = ord($chr);                # ... and its ordinal value

    if ($i == 0) {

        # Increment current memory block value by 1 until we have got the right
        # ordinal value.

        for (my $j = 0 ; $j < $ord ; ++ $j) {
            output('MoO');
        }

    } else {

        if ($ord > $prev_ord) {

            # Increment from previous value.

            for (my $j = $prev_ord ; $j < $ord ; ++ $j) {
                output('MoO');
            }

        } else {

            if (($prev_ord - $ord) <= $ord) {

                # Decrement from previous value.

                for (my $j = $prev_ord ; $j > $ord ; -- $j) {
                    output('MOo');
                }

            } else {

                # Reset current memory block value to 0, and increment to the
                # desired value.

                output('OOO');
                for (my $j = 0 ; $j < $ord ; ++ $j) {
                    output('MoO');
                }
            }
        }

    }

    # Print the character.

    output('Moo');

    $prev_ord = $ord;
}

print "\n" or die "$PROGNAME: print failed: $!\n";

# Emacs Local Variables:
# Emacs coding: us-ascii-unix
# Emacs End:
