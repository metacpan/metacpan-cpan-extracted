#
# bibliography package for Perl
#
# HTML routines
#
# Dana Jacobsen (dana@acm.org)
# 14 March 1996
#
#           All this is is a link to the output module.
#

package bp_html;

$version = "html (dj 14 mar 96)";

######

&bib'reg_format(
  'html',     # name
  'html',     # short name
  'bp_html',  # package name
  'html',     # default character set
  'suffix is html',
# functions
  'open      uses output',
  'close     uses output',
  'write     uses output',
  'clear     uses output',
  'read      uses output',
  'options   uses output',
  'implode   uses output',
  'explode   uses output',
  'tocanon   uses output',
  'fromcanon uses output',
);

######

#######################
# end of package
#######################

1;
