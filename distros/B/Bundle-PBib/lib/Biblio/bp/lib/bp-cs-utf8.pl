#
# bibliography package for Perl
#
# UTF8 character set.
#
# Peter Tandler <pbib@tandlers.de>
# Dec 1 2004
#
# adapted from bp_cs_88591

package bp_cs_utf8;
use 5.008; # for Unicode / utf-8 support

######

$bib'charsets{'utf8', 'i_name'} = 'utf8';

$bib'charsets{'utf8', 'tocanon'}  = "bp_cs_utf8'tocanon";
$bib'charsets{'utf8', 'fromcanon'} = "bp_cs_utf8'fromcanon";

$bib'charsets{'utf8', 'toesc'}   = "[\000]";  # we'd prefer to never call it
$bib'charsets{'utf8', 'fromesc'} = "${bib'cs_ext}|${bib'cs_meta}";
######

#####################


sub tocanon {
  $_[0];
}

######

sub fromcanon {
  local($_, $protect) = @_;
  local($repl, $unicode, $can);

  return $_ unless /$bib'cs_escape/o;

  1 while s/${bib'cs_ext}(....)/\X{$1}/g;

  while (/${bib'cs_meta}(....)/) {
    $repl = $1;
    $can = &bib'meta_approx($repl);
    defined $can  &&  s/$bib'cs_meta$repl/$can/g  &&  next;
    &bib'gotwarn("Can't convert ".&bib'meta_name($repl)." to UTF8");
    s/${bib'cs_meta}$repl//g;
  }

  $_;
}

#######################
# end of package
#######################

1;
