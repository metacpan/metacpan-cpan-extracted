#
# bibliography package for Perl
#
# None character set.  (for those formats with no character set)
#
# Dana Jacobsen (dana@acm.org)
# 18 November 1995

package bp_cs_none;

######

$bib'charsets{'none', 'i_name'} = 'none';

$bib'charsets{'none', 'tocanon'}  = "bp_cs_none'tocanon";
$bib'charsets{'none', 'fromcanon'} = "bp_cs_none'fromcanon";

$bib'charsets{'none', 'toesc'}   = "[\000]";
$bib'charsets{'none', 'fromesc'} = "[\x00-\x1F\200-\377]|${bib'cs_ext}|${bib'cs_meta}";

######

#$search =
#"\xc0\xc1\xc2\xc3\xc4\xc5\xc7\xc8\xc9\xcA\xcb\xcc\xcd\xce\xcf\xd1" .
#"\xd2\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdc\xdd" .
#"\xe0\xe1\xe2\xe3\xe4\xe5\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf1" .
#"\xf2\xf3\xf4\xf5\xf6\xf8\xf9\xfa\xfb\xfc\xfd\xff";
#
#$replace =
#"AAAAAACEEEEIIIIN" .
#"OOOOOOUUUUY" .
#"aaaaaaceeeeiiiin" .
#"oooooouuuuyy";
#
#&bib'goterror("cs-none search and replace lists are the wrong size!")
#   unless length($search) == length($replace);

######

sub tocanon {
  # Nothing for us to do.
  $_[0];
}

######

sub fromcanon {
  local($_) = @_;

  if (/[\200-\377]/) {
    #eval "tr/$search/$replace/";
    tr/\240\xc0\xc1\xc2\xc3\xc4\xc5\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd1\xd2\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdc\xdd/ AAAAAACEEEEIIIINOOOOOOUUUUY/;
    tr/\xe0\xe1\xe2\xe3\xe4\xe5\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf1\xf2\xf3\xf4\xf5\xf6\xf8\xf9\xfa\xfb\xfc\xfd\xff/aaaaaaceeeeiiiinoooooouuuuyy/;

    if (/[\200-\377]/) {
      s/\xC6/AE/g;
      s/\xE6/ae/g;
      s/[\200-\377]//g;
    }
  }

  if (/$bib'cs_escape/o) {
    local($repl, $can);
    s/${bib'cs_meta}....//g;
    while (/${bib'cs_ext}(....)/) {
      $repl = $1;
      $can = &bib'unicode_approx($repl);
      defined $can  &&  s/$bib'cs_ext$repl/$can/g  &&  next;
      s/${bib'cs_ext}$repl//g;
    }
  }
  tr/\x00-\x1F//d;

  $_;
}

#######################
# end of package
#######################

1;
