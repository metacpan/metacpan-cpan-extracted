#
# bibliography package for Perl
#
# troff character set.
#
# Dana Jacobsen (dana@acm.org)
# 13 January 1995, rewrote 20 November 1995 for new canon.
# Last modified on 23 March 1996.

package bp_cs_troff;

######

$bib'charsets{'troff', 'i_name'} = 'troff';

$bib'charsets{'troff', 'tocanon'}  = "bp_cs_troff'tocanon";
$bib'charsets{'troff', 'fromcanon'} = "bp_cs_troff'fromcanon";

$bib'charsets{'troff', 'toesc'}   = '[\\\\]';
$bib'charsets{'troff', 'fromesc'} = "[\\\\\200-\377]|${bib'cs_ext}|${bib'cs_meta}";

######

$opt_doublebs = 1;

# variables used throughout the package
$unicode = '';
$mine = '';
$can = '';

# Rather than defining all our maps and running code for reverse maps at
# load time, we're going to embed them in functions.  When tocanon or
# fromcanon get called, we do the init if we haven't already.  This should
# save startup time -- especially if they never actually call our function!
# In the troff code in particular, the tocanon code needs a lot of reverse
# maps and eval code.  If we're doing xyz->troff, we don't need to load
# all of that.
$cs_init    = 0;
$cs_to_init = 0;
$cs_fr_init = 0;

######

sub init_cs {

# This uses the Roman-8 mapping for the rarer Latin-1 characters.
# XXXXX We need to think about which particular mapping we think is
#	best for the characters that have multiple mappings.  We might
#	even want options for groff, Roman-8, -ms, etc.
%charmap = (
'00A0',	'\0',
'00A1',	'\(r!',
'00A2',	'\(ct',
'00A3',	'\(Po',
'00A4',	'\(Cs',
'00A5',	'\(Ye',
'00A6',	'\(bb',
'00A7',	'\(sc',
'00A8',	'\(ad',
'00A9',	'\(co',
'00AA',	'\(Of',
'00AB',	'\(Fo',
'00AC',	'\(no',
'00AD',	'\(hy',
'00AE',	'\(rg',
'00AF',	'\(a-',
'00B0',	'\(de',
'00B1',	'\(+-',
'00B2',	'\(S2',
'00B3',	'\(S3',
'00B4',	'\(aa',
'00B5',	'\(*m',
'00B6',	'\(ps',
'00B7',	'\(md',
'00B8',	'\(ac',
'00B9',	'\(S1',
'00BA',	'\(Om',
'00BB',	'\(Fc',
'00BC',	'\(14',
'00BD',	'\(12',
'00BE',	'\(34',
'00BF',	'\(r?',
'00C0',	'A\*`',
'00C1',	'A\*\'',
'00C2',	'A\*^',
'00C3',	'A\*~',
'00C4',	'A\*:',
'00C5',	'\(oA',
'00C6',	'\(AE',
'00C7',	'C\*,',
'00C8',	'E\*`',
'00C9',	'E\*\'',
'00CA',	'E\*^',
'00CB',	'E\*:',
'00CC',	'I\*`',
'00CD',	'I\*\'',
'00CE',	'I\*^',
'00CF',	'I\*:',
'00D0',	'\(-D',
'00D1',	'N\*~',
'00D2',	'O\*`',
'00D3',	'O\*\'',
'00D4',	'O\*^',
'00D5',	'O\*~',
'00D6',	'O\*:',
'00D7',	'\(mu',
'00D8',	'\(/O',
'00D9',	'U\*`',
'00DA',	'U\*\'',
'00DB',	'U\*^',
'00DC',	'U\*:',
'00DD',	'Y\*\'',
'00DE',	'\(TP',
'00DF',	'\(ss',
'00E0',	'a\*`',
'00E1',	'a\*\'',
'00E2',	'a\*^',
'00E3',	'a\*~',
'00E4',	'a\*:',
'00E5',	'\(oa',
'00E6',	'\(ae',
'00E7',	'c\*,',
'00E8',	'e\*`',
'00E9',	'e\*\'',
'00EA',	'e\*^',
'00EB',	'e\*:',
'00EC',	'i\*`',
'00ED',	'i\*\'',
'00EE',	'i\*^',
'00EF',	'i\*:',
'00F0',	'\(Sd',
'00F1',	'n\*~',
'00F2',	'o\*`',
'00F3',	'o\*\'',
'00F4',	'o\*^',
'00F5',	'o\*~',
'00F6',	'o\*:',
'00F7',	'\(di',
'00F8',	'\(/o',
'00F9',	'u\*`',
'00FA',	'u\*\'',
'00FB',	'u\*^',
'00FC',	'u\*:',
'00FD',	'y\*\'',
'00FE',	'\(Tp',
'00FF',	'y\*:',
'010D', 'c\*v',
'015F', 's\*,',
'017E', 'z\*v',
'2002',	'\ ',
'2003',	'\ \ ',
'2007',	'\|',  # I think this is wrong.  It's a "numsp" Number Space.
'2009',	'\^',
'2014',	'\-',
'201C',	'\*Q',
'201D',	'\*U',
);

%metamap = (
'0302',	'\u\s-3',  # superscript
'0312',	'\d\s-3',  # subscript
'030F',	'\s3\d',
'031F',	'\s3\u',
);

%fontmap = (
'0101', '\fR',
'0102', '\fI',
'0103', '\fB',
'0104', '\fC',
'0110', '\fP',	# simplistic, but it should work.
'0111', '\f1',	# we just go to font 1 when they want the previous font.
'0112', '\f1',	# or they end fonts.
'0113', '\f1',
'0114', '\f1',
);

  $cs_init = 1;
}

sub init_cs_fr {

  &init_cs unless $cs_init;

  # We're not using any eval strings at the moment, so there isn't anything
  # to do here.

  $cs_fr_init = 1;
}

sub init_cs_to {

  &init_cs unless $cs_init;

  # Build up a search string to do the reverse map.
  $cmap_eval = '';
  #$cmap_from_eval = '';
  %rmap = ();
  $mineE = '';

  # Step 1: Build a reverse map
  while (($unicode, $mine) = each %charmap) {
    $rmap{$mine} = &bib'unicode_to_canon( $unicode );
  }
  # Step 2: walk through the keys in sorted order
  #         (sigh, without a tree, this is still as slow as a dog)
  foreach $mine (sort keys %rmap) {
    $can = $rmap{$mine};
    $mineE = $mine;
    $mineE =~ s/(\W)/\\$1/g;
    if ( $mine !~ /\\\(../  &&  $mine !~ /.\\\*./ ) {
      $cmap_eval    .= "s/$mineE/$can/g;\n";
    }
    # This isn't being used right now.
    #$cmap_from_eval .= "s/$can/$mineE/g;\n";
  }
  # Leave rmap

  # These are characters that need to be mapped only in the to mapping.
  # There are a zillion different ways to write each symbol in troff, one for
  # each macro package and each implementation.
  # Nightmare 1: one troff character maps to different entities.  Example:
  #                  (groff)   \(Cs --> '00A4 CURRENCY SIGN
  #                  (roman8)  \(Cs --> '2660 BLACK SPADE SUIT
  # Nightmare 2: one entity maps to multiple characters, but no one of them
  #              is supported by a large group of implementations.
  %chartos = (
  'A\*a',		'00C5',
  'a\*a',		'00E5',
  'A\*o',		'00C5',
  'a\*o',		'00E5',
  'O\*/',		'00D8',
  'o\*/',		'00F8',
  '\*CC',		'010C',
  '\*Cc',		'010D',
  '\*CE',		'011A',
  '\*Ce',		'011B',
  '\*CL',		'013D',
  '\*Cl',		'013E',
  '\*CN',		'0147',
  '\*Cn',		'0148',
  '\*?',		'00BF',
  '\*!',		'00A1',
  '\(n~',		'00F1',
  );
  
  $cmap_to_eval = '';
  foreach $mine (sort keys %chartos) {
    $can = &bib'unicode_to_canon( $chartos{$mine} );
    $mineE = $mine;
    $mineE =~ s/(\W)/\\$1/g;
    if ( $mine !~ /\\\(../  &&  $mine !~ /.\\\*./ ) {
      $cmap_to_eval  .= "s/$mineE/$can/g;\n";
    } else {
      # Mapped up front with the rest.
      if (defined $rmap{$mine}) {
        &bib'goterror("Error in troff tables -- duplicate entry for $mine.");
      }
      $rmap{$mine} = $can;
    }
  }

  $cs_to_init = 1;
}


#####################


sub tocanon {
  local($_, $protect) = @_;

  &bib'panic("cs-troff tocanon called with no arguments!") unless defined $_;

  # always check to see if we have any characters to change
  # (with our toesc search string, is this first check necessary?)
  return $_  unless /\\/;

  # do this even if we don't have opt_doublebs on
  s/\\\\/\\/g;  

  &init_cs_to unless $cs_to_init;

  study;

  # Check for accents of the form \(xx and x\*x
  if (/\\[(*]/) {
    while (/(\\\(..)/) {
      $repl = $1;
      if (!defined $rmap{$repl}) {
        &bib'gotwarn("Unknown troff special $repl");
        $can = '';
      } else {
        $can = $rmap{$repl};
      }
      $repl =~ s/(\W)/\\$1/g;
      s/$repl/$can/g;
    }
    # Next check for all characters of the form x\*x
    while (/(.\\\*.)/) {
      $repl = $1;
      if (!defined $rmap{$repl}) {
        next if s/\\\*Q/${bib'cs_ext}201C/go;
        next if s/\\\*U/${bib'cs_ext}201D/go;
        &bib'gotwarn("Unknown troff special $repl");
        $can = '';
      } else {
        $can = $rmap{$repl};
      }
      $repl =~ s/(\W)/\\$1/g;
      s/$repl/$can/g;
    }

    return $_  unless /\\/;
  }

  eval $cmap_eval;

  return $_  unless /\\/;

  # OK, they've got something fairly weird.

  # Handle the different ways of specifying characters
  eval $cmap_to_eval;

  return $_  unless /\\/;

  if (/\\f[123RIBP]/) {
    # font changes
    while (/\\f([123RIBP])/) {
      $repl = $1;
      $repl eq 'P'    && ($mine = $bib'cs_meta . '0110');
      $repl =~ /[1R]/ && ($mine = $bib'cs_meta . '0101');
      $repl =~ /[2I]/ && ($mine = $bib'cs_meta . '0102');
      $repl =~ /[3B]/ && ($mine = $bib'cs_meta . '0103');
      s/\\f$repl/$mine/g;
    }
    $_ = &bib'font_check($_);
  }

  while (($unicode, $mine) = each %metamap) {
    $mine =~ s/(\W)/\\$1/g;
    s/$mine/${bib'cs_meta}$can/g;
  }

  return $_  unless /\\/;

  # Last of all, the escape character.  First we check to see if there is
  # anything else.  We can't delete it because of the way troff does it's
  # coding.
  if (/\\[^e]/) {
    &bib'gotwarn("Unknown troff characters in '$_'");
  }
  # Then convert the escape character
  s/\\e/\\/g;

  $_;
}

######

sub fromcanon {
  local($_, $protect) = @_;
  local($repl);

  &bib'panic("cs-troff fromcanon called with no arguments!") unless defined $_;

  s/\\/\\e/g;

  # tr/\200-\237//d && &bib'gotwarn("Zapped chars.");
  if (/[\200-\237]/) {
    while (/([\200-\237])/) {
      $repl = $1;
      $unicode = &bib'canon_to_unicode($repl);
      &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to troff");
      s/$repl//g;
    }
  }

  &init_cs_fr unless $cs_fr_init;

  # Which one of these to use probably depends on the frequency of
  # special characters.  The first method will be best with only one
  # or two, but the second is better if there are a lot.
  while (/([\240-\377])/g) {
    $repl = $1;
    $unicode = &bib'canon_to_unicode($repl);
    s/$repl/$charmap{$unicode}/g;
  }
  # Note that the definition of cmap_from_eval is now commented out above.
  #if (/[\240-\377]/) {
  #  eval $cmap_from_eval;
  #}

  # should we make the output have double backslashes?
  $opt_doublebs  &&  s/\\/\\\\/g;

  # Maybe we can go now?
  return $_ unless /$bib'cs_escape/o;

  while (/${bib'cs_ext}(....)/) {
    $unicode = $1;
    if ($unicode =~ /^00[0-7]/) {
      1 while s/${bib'cs_ext}00([0-7].)/pack("C", hex($1))/ge;
      next;
    }
    defined $charmap{$unicode} && s/${bib'cs_ext}$unicode/$charmap{$unicode}/g
                               && next;

    $can = &bib'unicode_approx($repl);
    defined $can  &&  s/$bib'cs_ext$repl/$can/g  &&  next;

    &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to troff");
    s/${bib'cs_ext}$unicode//g;
  }

  while (/${bib'cs_meta}(....)/) {
    $repl = $1;
    defined $fontmap{$repl} && s/${bib'cs_meta}$repl/$fontmap{$repl}/g
                            && next;
    defined $metamap{$repl} && s/${bib'cs_meta}$repl/$metamap{$repl}/g
                            && next;

    $can = &bib'meta_approx($repl);
    defined $can  &&  s/$bib'cs_meta$repl/$can/g  &&  next;

    &bib'gotwarn("Can't convert ".&bib'meta_name($repl)." to troff");
    s/${bib'cs_meta}$repl//g;
  }

  $_;
}

#######################
# end of package
#######################

1;
