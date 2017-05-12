#
# bibliography package for Perl
#
# dead-key character set.
#
# Dana Jacobsen (dana@acm.org)
# 14 March 1996
#
# This implements the common "dead-key" format.  From Oscar Nierstrasz's
# accent.pl:
#
# Examples:
# acute accent: \'a
# grave accent: \`e
# circumflex:   \^o (or \<o)
# dieresis:     \"u (or \:u)
# tilde:        \~n
# cedilla:      \,c
# slash:        \/o
#
# Also see <http://coombs.anu.edu.au/~marck/biblio4.htm>.
#
# For some of these, the TeX character set will suffice, but there are
# some differences, and TeX has a lot of extra stuff.
#

package bp_cs_dead;

######

$bib'charsets{'dead', 'i_name'} = 'dead';

$bib'charsets{'dead', 'tocanon'}   = "bp_cs_dead'tocanon";
$bib'charsets{'dead', 'fromcanon'} = "bp_cs_dead'fromcanon";

$bib'charsets{'dead', 'toesc'}   = "[\\\\]";
$bib'charsets{'dead', 'fromesc'} = "[\\\200-\377]|${bib'cs_ext}|${bib'cs_meta}";

######

# package variables for anyone to use
$repl = '';
$unicode = '';
$can = '';

######

# XXXXX Should charmap include the \ character also?

%charmap = (
#00A0
#00..
#00BE
#00BF  upside down ?
'00C0', '`A',
'00C1',q-'A-,
'00C2', '^A',
'00C3', '~A',
'00C4', '"A',
'00C5', 'AA',
'00C6', 'AE',
'00C7', ',C',
'00C8', '`E',
'00C9',q-'E-,
'00CA', '^E',
'00CB', '"E',
'00CC', '`I',
'00CD',q-'I-,
'00CE', '^I',
'00CF', '"I',
'00D0', '-D',
'00D1', '~N',
'00D2', '`O',
'00D3',q-'O-,
'00D4', '^O',
'00D5', '~O',
'00D6', '"O',
#00D7  times
'00D8', '/O',
'00D9', '`U',
'00DA',q-'U-,
'00DB', '^U',
'00DC', '"U',
'00DD',q-'Y-,
#00DE  Icelandic Thorn
'00DF', 'ss',
'00E0', '`a',
'00E1',q-'a-,
'00E2', '^a',
'00E3', '~a',
'00E4', '"a',
'00E5', 'aa',
'00E6', 'ae',
'00E7', ',c',
'00E8', '`e',
'00E9',q-'e-,
'00EA', '^e',
'00EB', '"e',
'00EC', '`i',
'00ED',q-'i-,
'00EE', '^i',
'00EF', '"i',
#00F0  Icelandic Eth
'00F1', '~n',
'00F2', '`o',
'00F3',q-'o-,
'00F4', '^o',
'00F5', '~o',
'00F6', '"o',
#00F7  div
'00F8', '/o',
'00F9', '`u',
'00FA',q-'u-,
'00FB', '^u',
'00FC', '"u',
'00FD',q-'y-,
#00FE  Icelandic thorn
'00FF', '"y',
'0107',q-'c-,
'010C', 'vC',
'010D', 'vc',
'0159', 'vr',
'015F', ',s',
'0160', 'vS',
'0161', 'vs',
'017A',q-'z-,
'017E', 'vz',
'0268',	'-i',
);

# Secondary mappings
%charmap2 = (
'sz',	'00DF',
);

# Build a reverse map and eval string
$reval = '';
while (($unicode, $repl) = each %charmap) {
  $can = &bib'unicode_to_canon( $unicode );
  if ($repl =~ /^[-`'^~",v]/) {
    $rmap{$repl} = $can;
  } else {
    $repl =~ s/(\W)/\\$1/g;
    $reval .= "s/\\\\$repl/$can/g;\n";
  }
}

# continue the same reverse map for the secondary mappings.
while (($repl, $unicode) = each %charmap2) {
  $can = &bib'unicode_to_canon( $unicode );
  if ($repl =~ /^[-`'^~",v]/) {
    $rmap{$repl} = $can;
  } else {
    $repl =~ s/(\W)/\\$1/g;
    $reval .= "s/\\\\$repl/$can/g;\n";
  }
}


######

sub tocanon {
  local($_, $protect) = @_;

  return $_ unless /\\/;

  s/\\:(\w)/\\"$1/g;
  s/\\<(\w)/\\^$1/g;

  while (/\\([-`'^~",v].)/) {
    $repl = $1;
    if (defined $rmap{$repl}) {
      s/\\$repl/$rmap{$repl}/g;
    } else {
      &bib'gotwarn("Couldn't parse dead-key accented character: $repl");
      s/\\$repl//g;
    }
  }

  return $_ unless /\\/;

  eval $reval;

  s/\\\\/$bib'cs_temp/go;
  if (!/\\/) {
    s/$bib'cs_temp/\\/go;
    return $_;
  }

  &bib'gotwarn("Unknown dead-key characters in '$_'");
  $_;
}

######

sub fromcanon {
  local($_, $protect) = @_;

  if ($protect) {
    s/\\/\\\\/go;
  }

  s/\240/ /g;
  s/\255/-/g;
  while (/([\200-\377])/) {
    $repl = $1;
    $unicode = &bib'canon_to_unicode($repl);
    if (defined $charmap{$unicode}) {
      s/$repl/\\$charmap{$unicode}/g;
    } else {
      &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to dead-key");
      s/$repl//g;
    }
  }

  return $_ unless /$bib'cs_escape/o;

  while (/${bib'cs_ext}(....)/) {
    $unicode = $1;
    if ($unicode =~ /^00[0-7]/) {   # 7-bit characters
      1 while s/${bib'cs_ext}00([0-7].)/pack("C", hex($1))/ge;
      next;
    }
    defined $charmap{$unicode} && s/${bib'cs_ext}$unicode/\\$charmap{$unicode}/g
                               && next;
    &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to dead-key");
    s/${bib'cs_ext}$unicode//g;
  }

  while (/${bib'cs_meta}(....)/) {
    $repl = $1;
    &bib'gotwarn("Can't convert ".&bib'meta_name($repl)." to dead-key");
    s/${bib'cs_meta}$repl//g;
  }

  $_;
}

######


#######################
# end of package
#######################

1;
