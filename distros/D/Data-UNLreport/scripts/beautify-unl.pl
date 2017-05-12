#!/usr/bin/perl -w #-d
#
# beautify-unl.pl - Output delimited columns in nice, even columns.

# Author: Jacob Salomon
#         jakesalomon@yahoo.com

# Options:
#   -d delimiter    The input delimiter that marks the columns.
#                   Default: | (Vertical bar)
#                   To specify a blank delimiter, use -db
#   -D delimiter    (Not implemented yet) The delimiter to use
#                   for output columns
# Parameters:
#   The input file[s].  Default: stdin
#
# Output is to stdout, using the same delimiter in the input
#
# Note that the original purpose of this utility was to straighten out
# the columns of an unloaded query in an Informix environment. As such,
# the default column delimiter is the | and each line does end in a
# delimiter, with nothing to follow.  Hence, the split() function will
# think it has parsed one more column that it actually has found.
#----------------------------------------------------------------------
# Author: $Author$
# Date:   $Date$
# Header information:
# $Id$
# Log messages:
# $Log$
#----------------------------------------------------------------------

# Release History:
# Release 1.0 2010-??-??
#   Rewrote in Perl from the original shell script
#
use strict;
#use carp;
use warnings;
#use diagnostics;

use Getopt::Std;

use Data::UNLreport;

use Data::Dumper;

my $program_name = $0;

my %opt_values;         # Hash for the option values the user specified
                        # on the command line
my $opt_string = "hd:D:"; # Specification of delimiters
my $def_in_delim = '|'; # Default input delimiter
#print Data::Dumper->Dump([\%main::], ["main"]), "\n==============\n";
#print Data::Dumper->Dump([\%UNLreport::], ["UNLreport"]), "\n";

#
# Begin parsing the command line.  (For now, simple enough)
#
my $white = '\s+';      # White-space pattern (routine)

my $ok_opts = getopts($opt_string, \%opt_values);
if (! $ok_opts)
{
  Usage();
  die "Please check your options list.";
};

# OK, options parsed successfully. What are they?
# OK, simple enough, optional input and output column delimiters
#
if (defined($opt_values{h}))
{ # Just asked for help. Give it and go away
  Usage();
  exit(0);
}
my $in_delim  = defined($opt_values{d})
              ? $opt_values{d} : $def_in_delim;
$in_delim = ' ' if ($in_delim eq 'b');  # User specified blank input delim

my $out_delim = defined($opt_values{D})
              ? $opt_values{D} : $in_delim;
$out_delim = ' ' if ($out_delim eq 'b');  # Specified blank output delim

my $p_file = Data::UNLreport->new(); # Create the object and
$p_file->in_delim($in_delim);   # set the input/output delimiters
$p_file->out_delim($out_delim);

my $in_line = "";                   # Line buffer
my $tally = -1;                     # Mainly for debugging
while ($in_line = <>)
{
  $tally = $p_file + $in_line;      # Throw the line to the beautifier
}
# All done: Print it out
#
$p_file->print();

#
sub HELP_MESSAGE
{
  my ($f_handle, $opt_pkg_name, $opt_pkg_version, $opt_string)
   = @_;    # (Not using these arguments at this time. -- JS)
  Usage();
}

sub Usage
{
  print <<EOT
Usage:
  $program_name --help
  $program_name [-d delimiter] [-D delimiter] [File] [File ...]

  --help: This help text

  -d: The 1-character delimiter of columns in the input file
      Default: The vertical bar (|).
      To specify a space as input delimiter, use -db

  -D: The 1-character delimiter to be used to separate the output
      columns. Default: The same as the input delimiter

  Files: The names of the input files, of course!
      Default: stdin

  All output is to stdout.
EOT
}
