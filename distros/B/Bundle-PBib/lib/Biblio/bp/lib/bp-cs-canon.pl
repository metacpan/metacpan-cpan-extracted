#
# bibliography package for Perl
#
# canon character set.
#
# Dana Jacobsen (dana@acm.org)
# 17 March 1996

package bp_cs_canon;

######

$bib'charsets{'canon', 'i_name'} = 'canon';

$bib'charsets{'canon', 'tocanon'}  = "bp_cs_canon'tocanon";
$bib'charsets{'canon', 'fromcanon'} = "bp_cs_canon'fromcanon";

$bib'charsets{'canon', 'toesc'}   = "[\000]";  # we'd prefer to never call it
$bib'charsets{'canon', 'fromesc'} = "[\000]";
######

#####################


sub tocanon {
  $_[0];
}

######

sub fromcanon {
  $_[0];
}

#######################
# end of package
#######################

1;
