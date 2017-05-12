#
# bibliography package for Perl
#
# ISO-8859-1 character set.
#
# This is really easy since this is the canonical character set, with the
# exception of the escape character.
#
# Dana Jacobsen (dana@acm.org)
# 18 November 1995

package bp_cs_88591;

######

$bib'charsets{'8859-1', 'i_name'} = '8859-1';

$bib'charsets{'8859-1', 'tocanon'}  = "bp_cs_88591'tocanon";
$bib'charsets{'8859-1', 'fromcanon'} = "bp_cs_88591'fromcanon";

$bib'charsets{'8859-1', 'toesc'}   = "[\000]";  # we'd prefer to never call it
$bib'charsets{'8859-1', 'fromesc'} = "${bib'cs_ext}|${bib'cs_meta}";
######

#####################


sub tocanon {

  # We're eight bit ISO-8859-1, so there isn't anything for us to do.
  # We assume here that the escape character is already done.

  $_[0];
}

######

sub fromcanon {
  local($_, $protect) = @_;
  local($repl, $unicode, $can);

  return $_ unless /$bib'cs_escape/o;

  1 while s/${bib'cs_ext}00(..)/&bib'unicode_to_canon('00'.$1)/ge;

  while (/${bib'cs_ext}(....)/) {
    $unicode = $1;
    $can = &bib'unicode_approx($unicode);
    defined $can  &&  s/$bib'cs_ext$unicode/$can/g  &&  next;
    &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to ISO-8859-1");
    s/${bib'cs_ext}$unicode//g;
  }
  while (/${bib'cs_meta}(....)/) {
    $repl = $1;
    $can = &bib'meta_approx($repl);
    defined $can  &&  s/$bib'cs_meta$repl/$can/g  &&  next;
    &bib'gotwarn("Can't convert ".&bib'meta_name($repl)." to ISO-8859-1");
    s/${bib'cs_meta}$repl//g;
  }

  $_;
}

#######################
# end of package
#######################

1;
