#
# bibliography package for Perl
#
# TeX character set.
#
# Dana Jacobsen (dana@acm.org)
# 22 January 1995 (last modified on 14 March 1996)
#
# These routines have gone through a major update in November 1995.
#
# This is still in beta.
# There are many characters not implemented, and the underlying charset
# code is not solid yet.
#
# Some ugly convolutions are gone through to make it run at a decent
# speed.  This code is _very_ timing sensitive.  On a typical 1043 record
# run, the first implementation ran at 83 seconds for tocanon, 28 seconds
# for fromcanon.  Two days of work brought this down to 1 second and 2
# seconds.
# Lesson:
#    If you're not careful, you may find the charset code dominating
#    your entire conversion time since it is run for every _field_, but
#    with some careful profiling, it can be very fast.
#


####
#
# ToDo's identified by ptandler, 02-07-18
#
# - Unknown TeX characters in 'ACM SIG{\-}PLAN Notices' --> \- is an optional hyphen
# - Unknown TeX characters in '\{lopez,borning\}@cs' --> \{ and \} protect braces
# - braces are not removed ... in bibtex they are often needed to protect the case of words
#    that should not be converted to lowercase in titles.
# - tex commands like \cite{....} in bibtex entries are treated as unknown tex characters
#
####

package bp_cs_tex;

######

$bib'charsets{'tex', 'i_name'} = 'tex';

$bib'charsets{'tex', 'tocanon'}   = "bp_cs_tex'tocanon";
$bib'charsets{'tex', 'fromcanon'} = "bp_cs_tex'fromcanon";

$bib'charsets{'tex', 'toesc'}   = "[\$\\\\]";
# XXXXX We have so many characters to protect, should we even bother?
$bib'charsets{'tex', 'fromesc'} = "[\\#\$\%\&{}_\|><\^~\200-\377]|${bib'cs_ext}|${bib'cs_meta}";

######

$cs_init = 0;

# package variables for anyone to use
$mine = '';
$unicode = '';
$can = '';

######

sub init_cs {

# Thorn and eth are really nasty since they don't exist in the standard TeX
# fonts.  This is what I came up with in r2b to fake it.  Fortunately they
# aren't used often.  Get the cmoer fonts if you want to do them right.
# My eth is pretty nice, but the thorn leaves a little to be desired.

%charmap = (
'00A1', "!'",
'00A2', '\leavevmode\hbox{\rm\rlap/c}',
'00A3', '{\pounds}',
'00A4', '$\spadesuit$',
'00A5', '\leavevmode\hbox{\rm\rlap=Y}',
'00A6', '\leavevmode
         \hbox{\hskip.4ex\hbox{\ooalign{\vrule width.2ex height.5ex depth.4ex\crcr
         \hfil\raise.8ex\hbox{\vrule width.2ex height.9ex depth0ex}\hfil}}}',
'00A7', '\S ',
'00A8', '{\"{ }}',
'00A9', '\leavevmode\hbox{\raise.6em\hbox{\copyright}}',
'00AA', '${}^{\b{\scriptsize a}}$',
'00AB', '$\scriptscriptstyle\ll$',
'00AC', '$\neg$',
'00AE', '\leavevmode\hbox{\raise.6em\hbox{\ooalign{{\mathhexbox20D}\crcr
         \hfil\raise.07ex\hbox{r}\hfil}}}',
'00AF', '{\={ }}',
'00B0', '${}^\circ$',
'00B1', '$\pm$',
'00B2', '${}^2$',
'00B3', '${}^3$',
'00B4', '{\'{ }}',
'00B5', '$\mu$',
'00B6', '\P ',
'00B7', '$\cdot$',
'00B8', '{\c{ }}',
'00B9', '${}^1$',
'00BA', '${}^{\b{\scriptsize o}}$',
'00BB', '$\scriptscriptstyle\gg$',
'00BC', '$1\over4$',
'00BD', '$1\over2$',
'00BE', '$3\over4$',
'00BF', '?`',
'00C0', '{\`A}',
'00C1', q-{\'A}-,
'00C2', '{\^A}',
'00C3', '{\~A}',
'00C4', '{\"A}',
'00C5', '{\AA}',
'00C6', '{\AE}',
'00C7', '{\c{C}}',
'00C8', '{\`E}',
'00C9', q-{\'E}-,
'00CA', '{\^E}',
'00CB', '{\"E}',
'00CC', '{\`I}',
'00CD', q-{\'I}-,
'00CE', '{\^I}',
'00CF', '{\"I}',
'00D0', '\leavevmode\hbox{\ooalign{{D}\crcr
         \hskip.2ex\raise.25ex\hbox{-}\hfil}}',
'00D1', '{\~N}',
'00D2', '{\`O}',
'00D3', q-{\'O}-,
'00D4', '{\^O}',
'00D5', '{\~O}',
'00D6', '{\"O}',
'00D7', '$\times$',
'00D8', '{\O}',
'00D9', '{\`U}',
'00DA', q-{\'U}-,
'00DB', '{\^U}',
'00DC', '{\"U}',
'00DD', q-{\'Y}-,
'00DE', '\leavevmode\hbox{I\hskip-.6ex\raise.5ex\hbox{$\scriptscriptstyle\supset$}}',
'00DF', '{\ss}',
'00E0', '{\`a}',
'00E1', q-{\'a}-,
'00E2', '{\^a}',
'00E3', '{\~a}',
'00E4', '{\"a}',
'00E5', '{\aa}',
'00E6', '{\ae}',
'00E7', '{\c{c}}',
'00E8', '{\`e}',
'00E9', q-{\'e}-,
'00EA', '{\^e}',
'00EB', '{\"e}',
'00EC', '{\`i}',
'00ED', q-{\'i}-,
'00EE', '{\^i}',
'00EF', '{\"i}',
'00F0', '\leavevmode\hbox{\ooalign{$\partial$\crcr\hskip.8ex\raise.7ex\hbox{-}\hfil}}',
'00F1', '{\~n}',
'00F2', '{\`o}',
'00F3', q-{\'o}-,
'00F4', '{\^o}',
'00F5', '{\~o}',
'00F6', '{\"o}',
'00F7', '$\div$',
'00F8', '{\o}',
'00F9', '{\`u}',
'00FA', q-{\'u}-,
'00FB', '{\^u}',
'00FC', '{\"u}',
'00FD', q-{\'y}-,
'00FE', '\leavevmode\hbox{{\lower.3ex\hbox{\large l}}\hskip-.52ex o}',
'00FF', '{\"y}',
'0107', q-{\'c}-,
'010C', '{\vC}',
'010D', '{\vc}',
'0159', '{\vr}',
'015F', '{\c{s}}',
'0160', '{\vS}',
'0161', '{\vs}',
'017A', q-{\'z}-,
'017E', '{\vz}',
# XXXXX
# Should these be surrounded by $ (math mode)?
# Also, what to do with \mu, which is listed twice?
'03B1', '\alpha',
'03B2', '\beta',
'03B3', '\gamma',
'03B4', '\delta',
'03B5', '\epsilon',
'03B6', '\zeta',
'03B7', '\eta',
'03B8', '\theta',
'03B9', '\iota',
'03BA', '\kappa',
'03BB', '\lambda',
'03BC', '\mu',
'03BD', '\nu',
'03BE', '\xi',
'03C0', '\pi',
'03C1', '\rho',
'03C2', '\varsigma',
'03C3', '\sigma',
'03C4', '\tau',
'03C5', '\upsilon',
'03C6', '\phi',
'03C7', '\chi',
'03C8', '\psi',
'03C9', '\omega',
'2007', '$\:$',
'2009', '$\,$',
'201C', '``',
'201D', '\'\'',
);

# This mapping is only used in the from section.  We'll do these by hand
# in the to mapping.
%charmap2 = (
'00A0', '~',
'00AD', '-',
'2002', '\ ',
'2003', '\ \ ',
'2014', '---',
'03BF', 'o',
);

# Blah.  TeX has such a non-uniform way of handling characters that this is
# really slow.  I'm going to try some optimizations for the tocanon code
# since that will be heavily used.  It makes this stuff less uniform though.
# Remember that we don't have a full TeX parser, or even a partial one.

# Build up a search string to do the reverse map.
$cmap_to_eval = '';
$cmap_from8_eval = '';
$cmap_to_eval_1 = '';
$cmap_to_eval_2 = '';
%rmap = ();
%accent = ();

# Step 1: Build a reverse map
while (($unicode, $mine) = each %charmap) {
  $rmap{$mine} = $unicode;
}
# Step 2: walk through the keys in sorted order
local($mineE);
foreach $mine (sort keys %rmap) {
  $can = &bib'unicode_to_canon( $rmap{$mine} );
  $mineE = $mine;
  $mineE =~ s/(\W)/\\$1/g;
  # The various maps for tocanon
  if ($mine =~ /^{\\([`'^"~])([\w])}$/) {
    $accent{$1 . $2} = $can;
  } elsif ($mine =~ /^{\\([vc])(\w)}$/) {
    $accent{$1 . $2} = $can;
  } elsif ($mine =~ /^{\\([vc]){(\w)}}$/) {
    $accent{$1 . $2} = $can;
  } elsif ($mine =~ /leavevmode/) {
    $cmap_to_eval_1 .= "s/$mineE/$can/g;\n";
  } elsif ($mine =~ /\$/) {
    $cmap_to_eval_2 .= "s/$mineE/$can/g;\n";
  } else {
    $cmap_to_eval   .= "s/$mineE/$can/g;\n";
  }
  if ( length($can) == 1 ) {
    $cmap_from8_eval .= "s/$can/$mineE/g;\n";
  }
}
$cmap_from8_eval .= "s/\\240/\\~/g;\ns/\\255/-/g;";
# leave rmap

#%map_diac = (
#'tilde',	'\~{}',
#'circ',		'\^{}',
#'lcub',		'$\lbrace$',
#'rcub',		'$\rbrace$',
#'bsol',		'$\backslash$',
#);

# Careful. This is from only.
%metamap = (
'3100', '{',   # Begin protection
'3110', '}',   # End   protection
               # fonts
'0101', '{\rm ',
'0102', '{\it ',
'0103', '{\bf ',
'0111', '}',
'0112', '}',
'0113', '}',
'0110', '}',	# previous font.  We don't need a font stack to handle it.
'2102', '{\em ',
'2112', '}',
);

  $cs_init = 1;
}

######

sub tocanon {
  local($_, $protect) = @_;

  # unprotect the TeX characters
  if ($protect) {
    # input  is assumed to be in TeX format, before _any_ canon processing.
    # output is TeX format, but with raw magic characters.
    s/\$>\$/>/g;
    s/\$<\$/</g;
    s/\$\|\$/\|/g;
    s/\\_/_/g;
    s/\$\\rbrace\$/}/g;
    s/\$\\lbrace\$/{/g;
    s/\\\&/\&/g;
    s/\\\%/\%/g;
    s/\\\$/\$/g;
    s/\\#/#/g;
  }

  if (/-/) {
    s/\$-\$/${bib'cs_ext}2212/go;
    s/\b---\b/${bib'cs_ext}2014/go;
    s/\b--\b/${bib'cs_ext}2013/go;
    # leave -
  }
  if (/~/) {
    1 while s/([^\\])~/$1\240/g;
  }
  s/\\ \\ /${bib'cs_ext}2003/go;
  s/\\ /${bib'cs_ext}2002/go;

  # Can we go now?
  return $_ unless /\\/;

  &init_cs unless $cs_init;

  if (/\\[`'^"~vc][{ ]?[\w]/) {
    # ISO -- we try {\"{c}}, {\"c}, \"{c}, \"c
    #                        ^^^^^
    #                      preferred
    #
    # XXXXX What do we do about all the other ways they can try?
    #       mgnet.bib uses {\" u} a lot.  (got this way now)

    while (/{\\([`'^"~vc])( ?)([\w])}/) {
      $can = $accent{$1 . $3};
      $mine = "{\\$1$2$3}";
      if (!defined $can) {
        &bib'gotwarn("Can't convert TeX '$mine' in $_ to canon");
        $can = '';
      }
      $mine =~ s/(\W)/\\$1/g;
      s/$mine/$can/g;
    }
    while (/{\\([`'^"~vc]){([\w])}}/) {
      $can = $accent{$1 . $2};
      $mine = "{\\$1\{$2\}}";
      if (!defined $can) {
        &bib'gotwarn("Can't convert TeX '$mine' in $_ to canon");
        $can = '';
      }
      $mine =~ s/(\W)/\\$1/g;
      s/$mine/$can/g;
    }
    while (/\\([`'^"~vc]){([\w])}/) {
      $can = $accent{$1 . $2};
      $mine = "\\$1\{$2\}";
      if (!defined $can) {
        &bib'gotwarn("Can't convert TeX '$mine' in $_ to canon");
        $can = '';
      }
      $mine =~ s/(\W)/\\$1/g;
      s/$mine/$can/g;
    }
    while (/\\([`'^"~])( ?)([\w])/) {
      $can = $accent{$1 . $3};
      $mine = "\\$1$2$3";
      if (!defined $can) {
        &bib'gotwarn("Can't convert TeX '$mine' in $_ to canon");
        $can = '';
      }
      $mine =~ s/(\W)/\\$1/g;
      s/$mine/$can/g;
    }

    # This unfortunately matches \cr and \circ.  We aren't doing a loop
    # any more, so it's not even necessary anymore.  Let the standard
    # routine try to match and give the normal error message on failure.
    #while (s/(\\[`'^"~vc][{ ]?[\w])//) {
    #  &bib'gotwarn("Couldn't parse TeX accented character: $1!");
    #}

    return $_ unless /\\/;
  } # end of standard accented characters

  # XXXXX What about the v, c, and other accents?  Do we need another
  #       section for those, or can we fit them in above?

  if (/leavevmode/) {
    eval $cmap_to_eval_1;
  }
  if (/\$/) {
    eval $cmap_to_eval_2;
  }
  eval $cmap_to_eval;

  s/\\\^{}/\^/g;
  s/\\~{\s?}/~/g;

  # hopefully we're done by now
  return $_ unless /\\/;

  # font changes
  # This doesn't work all that well, but most bibliographies are simple
  s/\{\\rm ([^{}]*)\}/${bib'cs_meta}0101$1${bib'cs_meta}0110/g;
  s/\{\\it ([^{}]*)\}/${bib'cs_meta}0102$1${bib'cs_meta}0110/g;
  s/\{\\bf ([^{}]*)\}/${bib'cs_meta}0103$1${bib'cs_meta}0110/g;
  s/\{\\em ([^{}]*)\}/${bib'cs_meta}2102$1${bib'cs_meta}2112/g;
  $_ = &bib'font_check($_) if /${bib'cs_meta}01/o;
  # done with font changing

  return $_ unless /\\/;

  s/\$\\backslash\$/$bib'cs_temp/g;
  if (!/\\/) {
    s/$bib'cs_temp/\\/go;
    return $_;
  }
  s/$bib'cs_temp/\\/go;

  # I give up.
  # XXXXX We really ought to remove the escape and meta characters we have
  #       converted when we give them this warning.
  &bib'gotwarn("Unknown TeX characters in '$_'");
  $_;
}

######

sub fromcanon {
  local($_, $protect) = @_;
  local($repl);
  # We no longer check for font matching here, as that should be done by a
  # call to bib'font_check in the tocanon code.

  if ($protect) {
    s/\\/$bib'cs_temp/go;
    s/#/\\#/g;
    s/\$/\\\$/g;
    s/\%/\\\%/g;
    s/\&/\\\&/g;
    s/{/\$\\lbrace\$/g;
    s/}/\$\\rbrace\$/g;
    s/_/\\_/g;
    s/\|/\$\|\$/g;
    s/>/\$>\$/g;
    s/</\$<\$/g;
    s/\^/\\^{}/g;
    s/~/\\~{}/g;
    s/$bib'cs_temp/\$\\backslash\$/go;
  }

  while (/([\200-\237])/) {
    $repl = $1;
    $unicode = &bib'canon_to_unicode($repl);
    &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to TeX");
    s/$repl//g;
  }

  &init_cs unless $cs_init;

  #if (/[\240-\377]/) {
  #  eval $cmap_from8_eval;
  #}
  s/\240/~/g;
  s/\255/-/g;
  while (/([\240-\377])/) {
    $repl = $1;
    $unicode = &bib'canon_to_unicode($repl);
    s/$repl/$charmap{$unicode}/g;
  }

  # Maybe we can go now?
  return $_ unless /$bib'cs_escape/o;

  while (/${bib'cs_ext}(....)/) {
    $unicode = $1;
    if ($unicode =~ /^00[0-7]/) {
      1 while s/${bib'cs_ext}00([0-7].)/pack("C", hex($1))/ge;
      next;
    }
    defined $charmap{$unicode}  && s/${bib'cs_ext}$unicode/$charmap{$unicode}/g
                                && next;
    defined $charmap2{$unicode} && s/${bib'cs_ext}$unicode/$charmap2{$unicode}/g
                                && next;

    $can = &bib'unicode_approx($unicode);
    defined $can  &&  s/$bib'cs_ext$unicode/$can/g  &&  next;

    &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to TeX");
    s/${bib'cs_ext}$unicode//g;
  }

  while (/${bib'cs_meta}(....)/) {
    $repl = $1;
    defined $metamap{$repl} && s/${bib'cs_meta}$repl/$metamap{$repl}/g
                            && next;

    $can = &bib'meta_approx($repl);
    defined $can  &&  s/$bib'cs_meta$repl/$can/g  &&  next;

    &bib'gotwarn("Can't convert ".&bib'meta_name($repl)." to TeX");
    s/${bib'cs_meta}$repl//g;
  }

  $_;
}

######


#######################
# end of package
#######################

1;
