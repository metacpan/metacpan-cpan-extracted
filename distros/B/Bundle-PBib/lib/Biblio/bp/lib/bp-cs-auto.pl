#
# bibliography package for Perl
#
# auto character set.
#
# Dana Jacobsen (dana@acm.org)
# 13 January 1995

# There is no auto recognition of character sets yet, and may never be.
# These routines shouldn't ever be called, but we're going to set things
# up just in case.

package bp_cs_auto;

######

$bib'charsets{'auto', 'i_name'} = 'auto';

$bib'charsets{'auto', 'tocanon'}  = "bp_cs_auto'tocanon";
$bib'charsets{'auto', 'fromcanon'} = "bp_cs_auto'fromcanon";

######

# For now we make these a bit harsh, as they shouldn't be called

sub tocanon {
  &bib'panic("called charset auto tocanon");
  return &bib'goterror("called charset auto tocanon");
}

######

sub fromcanon {
  &bib'panic("called charset auto tocanon");
  return &bib'goterror("called charset auto fromcanon");
}

#######################
# end of package
#######################

1;
