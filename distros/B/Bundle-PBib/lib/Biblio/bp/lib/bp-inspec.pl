#
# bibliography package for Perl
#
# INSPEC routines
#
# Dana Jacobsen (dana@acm.org)
# 15 January 1996
#
# For information about INSPEC, see
#   <http://cipserv1.physik.uni-ulm.de/www_allg/litrech/insdata.htm>
# This WWW page describes what I will call style 0.
#
# Style numbers correspond to those used by Vince Darley's bibConvert.tcl
# program, except for style 0 which he does not support.
#
#   0:  Records begin with "AN".
#   1:  All lines begin with a "|", maybe looks like style 3?
#   2:  Records begin with "Document N", mixed case tags
#   3:  Records begin with "Citation N", upper case tags
#   4:  Records begin with "Doc Type", mixed case tags
#   5:  Records begin with "   RECORD NO.:"
#   6:  Records begin with "1. (INSPEC result)"
#
#
# To support the multiple INSPEC formats, we can:
#
#   1) make a seperate format module for each style, and have the users use
#      them only.
#
#   2) do (1), and also make an inspec format that can select between them.
#      This is what we currently do.
#
#   3) Pick a standard style (style 0, for instance), and make the explode
#      routine convert from other styles to this style.
#
# The advantage of number 3 is that it gives a coherent view to all INSPEC
# files before we need to convert.  Note that it should be possible to auto
# detect which style we've been given.
#

package bp_inspec;

$version = "inspec (dj 15 jan 96)";

######

$opt_style = 4;

if ($opt_style == 4) {
  &bib'reg_format(
    'inspec',    # name
    'isp',       # short name
    'bp_inspec', # package name
    '8859-1',    # default character set
    'suffix is inspec',
  # functions
    'options',
    'open      uses inspec4',
    'close     uses inspec4',
    'write     uses inspec4',
    'clear     uses inspec4',
    'read      uses inspec4',
    'explode   uses inspec4',
    'implode   uses inspec4',
    'tocanon   uses inspec4',
    'fromcanon uses inspec4',
  );
} else {
  &bib'goterror("Unknown INSPEC style: $opt_style");
}

######

sub options {
  local($opts) = @_;

  print "setting options to $opts\n";
}


#######################
# end of package
#######################

1;
