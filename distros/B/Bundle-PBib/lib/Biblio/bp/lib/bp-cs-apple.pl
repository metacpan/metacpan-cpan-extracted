#
# bibliography package for Perl
#
# Apple Macintosh character set.
#
# Values derived from the C3 project's "def-apple-1.txta" file.
#
# Dana Jacobsen (dana@acm.org)
# 22 November 1995

package bp_cs_apple;

######

$bib'charsets{'apple', 'i_name'} = 'apple';

$bib'charsets{'apple', 'tocanon'}  = "bp_cs_apple'tocanon";
$bib'charsets{'apple', 'fromcanon'} = "bp_cs_apple'fromcanon";

$bib'charsets{'apple', 'toesc'}   = "[\200-\377]";
$bib'charsets{'apple', 'fromesc'} = "[\200-\377]|${bib'cs_ext}|${bib'cs_meta}";

######


######

# The maps.
#
# $umap is an associative array mapping Unicode text --> 8bit
#
# $nmap is an array mapping 8bit --> Unicode text
#

# Converted from C3 (TERENA) table
# Read 256 values.
# Table is ISO-8859-1 in 7 bits.

# Table follows:
%umap = (
'00C4', 128,  # LATIN CAPITAL LETTER A WITH DIAERESIS
'00C5', 129,  # LATIN CAPITAL LETTER A WITH RING ABOVE
'00C7', 130,  # LATIN CAPITAL LETTER C WITH CEDILLA
'00C9', 131,  # LATIN CAPITAL LETTER E WITH ACUTE
'00D1', 132,  # LATIN CAPITAL LETTER N WITH TILDE
'00D6', 133,  # LATIN CAPITAL LETTER O WITH DIAERESIS
'00DC', 134,  # LATIN CAPITAL LETTER U WITH DIAERESIS
'00E1', 135,  # LATIN SMALL LETTER A WITH ACUTE
'00E0', 136,  # LATIN SMALL LETTER A WITH GRAVE
'00E2', 137,  # LATIN SMALL LETTER A WITH CIRCUMFLEX
'00E4', 138,  # LATIN SMALL LETTER A WITH DIAERESIS
'00E3', 139,  # LATIN SMALL LETTER A WITH TILDE
'00E5', 140,  # LATIN SMALL LETTER A WITH RING ABOVE
'00E7', 141,  # LATIN SMALL LETTER C WITH CEDILLA
'00E9', 142,  # LATIN SMALL LETTER E WITH ACUTE
'00E8', 143,  # LATIN SMALL LETTER E WITH GRAVE
'00EA', 144,  # LATIN SMALL LETTER E WITH CIRCUMFLEX
'00EB', 145,  # LATIN SMALL LETTER E WITH DIAERESIS
'00ED', 146,  # LATIN SMALL LETTER I WITH ACUTE
'00EC', 147,  # LATIN SMALL LETTER I WITH GRAVE
'00EE', 148,  # LATIN SMALL LETTER I WITH CIRCUMFLEX
'00EF', 149,  # LATIN SMALL LETTER I WITH DIAERESIS 
'00F1', 150,  # LATIN SMALL LETTER N WITH TILDE     
'00F3', 151,  # LATIN SMALL LETTER O WITH ACUTE     
'00F2', 152,  # LATIN SMALL LETTER O WITH GRAVE     
'00F4', 153,  # LATIN SMALL LETTER O WITH CIRCUMFLEX
'00F6', 154,  # LATIN SMALL LETTER O WITH DIAERESIS 
'00F5', 155,  # LATIN SMALL LETTER O WITH TILDE     
'00FA', 156,  # LATIN SMALL LETTER U WITH ACUTE     
'00F9', 157,  # LATIN SMALL LETTER U WITH GRAVE     
'00FB', 158,  # LATIN SMALL LETTER U WITH CIRCUMFLEX
'00FC', 159,  # LATIN SMALL LETTER U WITH DIAERESIS 
'2020', 160,  # DAGGER
'00B0', 161,  # DEGREE SIGN
'00A2', 162,  # CENT SIGN
'00A3', 163,  # POUND SIGN
'00A7', 164,  # SECTION SIGN
'2022', 165,  # BULLET
'00B6', 166,  # PILCROW SIGN
'00DF', 167,  # LATIN SMALL LETTER SHARP S (German)
'00AE', 168,  # REGISTERED SIGN
'00A9', 169,  # COPYRIGHT SIGN
'2122', 170,  # TRADE MARK SIGN
'00B4', 171,  # ACUTE ACCENT
'00A8', 172,  # DIAERESIS
'2260', 173,  # NOT EQUAL TO
'00C6', 174,  # LATIN CAPITAL LIGATURE AE
'00D8', 175,  # LATIN CAPITAL LETTER O WITH STROKE
'221E', 176,  # INFINITY
'00B1', 177,  # PLUS-MINUS SIGN
'2264', 178,  # LESS-THAN OR EQUAL TO
'2265', 179,  # GREATER-THAN OR EQUAL TO
'00A5', 180,  # YEN SIGN
'00B5', 181,  # MICRO SIGN
'2202', 182,  # PARTIAL DIFFERENTIAL
'2211', 183,  # N-ARY SUMMATION
'220F', 184,  # N-ARY PRODUCT
'03C0', 185,  # GREEK SMALL LETTER PI
'222B', 186,  # INTEGRAL
'00AA', 187,  # FEMININE ORDINAL INDICATOR
'00BA', 188,  # MASCULINE ORDINAL INDICATOR
'03A9', 189,  # GREEK CAPITAL LETTER OMEGA
'00E6', 190,  # LATIN SMALL LIGATURE AE
'00F8', 191,  # LATIN SMALL LETTER O WITH STROKE
'00BF', 192,  # INVERTED QUESTION MARK
'00A1', 193,  # INVERTED EXCLAMATION MARK
'00AC', 194,  # NOT SIGN
'221A', 195,  # SQUARE ROOT
'0192', 196,  # LATIN SMALL LETTER F WITH HOOK
'2248', 197,  # ALMOST EQUAL TO
'0394', 198,  # GREEK CAPITAL LETTER DELTA
'00AB', 199,  # LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
'00BB', 200,  # RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
'2026', 201,  # HORIZONTAL ELLIPSIS
'00A0', 202,  # NO-BREAK SPACE
'00C0', 203,  # LATIN CAPITAL LETTER A WITH GRAVE
'00C3', 204,  # LATIN CAPITAL LETTER A WITH TILDE
'00D5', 205,  # LATIN CAPITAL LETTER O WITH TILDE
'0152', 206,  # LATIN CAPITAL LIGATURE OE
'0153', 207,  # LATIN SMALL LIGATURE OE
'2013', 208,  # EN DASH
'2014', 209,  # EM DASH
'201C', 210,  # LEFT DOUBLE QUOTATION MARK
'201D', 211,  # RIGHT DOUBLE QUOTATION MARK
'2018', 212,  # LEFT SINGLE QUOTATION MARK
'2019', 213,  # RIGHT SINGLE QUOTATION MARK
'00F7', 214,  # DIVISION SIGN
'25CA', 215,  # LOZENGE
'00FF', 216,  # LATIN SMALL LETTER Y WITH DIAERESIS
'0178', 217,  # LATIN CAPITAL LETTER Y WITH DIAERESIS
'2044', 218,  # FRACTION SLASH
'00A4', 219,  # CURRENCY SIGN
'2039', 220,  # SINGLE LEFT-POINTING ANGLE QUOTATION MARK
'203A', 221,  # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
'FB01', 222,  # LATIN SMALL LIGATURE FI
'FB02', 223,  # LATIN SMALL LIGATURE FL
'2021', 224,  # DOUBLE DAGGER
'00B7', 225,  # MIDDLE DOT
'201A', 226,  # SINGLE LOW-9 QUOTATION MARK
'201E', 227,  # DOUBLE LOW-9 QUOTATION MARK
'2030', 228,  # PER MILLE SIGN
'00C2', 229,  # LATIN CAPITAL LETTER A WITH CIRCUMFLEX
'00CA', 230,  # LATIN CAPITAL LETTER E WITH CIRCUMFLEX
'00C1', 231,  # LATIN CAPITAL LETTER A WITH ACUTE
'00CB', 232,  # LATIN CAPITAL LETTER E WITH DIAERESIS
'00C8', 233,  # LATIN CAPITAL LETTER E WITH GRAVE
'00CD', 234,  # LATIN CAPITAL LETTER I WITH ACUTE
'00CE', 235,  # LATIN CAPITAL LETTER I WITH CIRCUMFLEX
'00CF', 236,  # LATIN CAPITAL LETTER I WITH DIAERESIS
'00CC', 237,  # LATIN CAPITAL LETTER I WITH GRAVE
'00D3', 238,  # LATIN CAPITAL LETTER O WITH ACUTE
'00D4', 239,  # LATIN CAPITAL LETTER O WITH CIRCUMFLEX
'E000', 240,  # APPLE LOGO
'00D2', 241,  # LATIN CAPITAL LETTER O WITH GRAVE
'00DA', 242,  # LATIN CAPITAL LETTER U WITH ACUTE
'00DB', 243,  # LATIN CAPITAL LETTER U WITH CIRCUMFLEX
'00D9', 244,  # LATIN CAPITAL LETTER U WITH GRAVE
'0131', 245,  # LATIN SMALL LETTER DOTLESS I
'02C6', 246,  # MODIFIER LETTER CIRCUMFLEX ACCENT
'02DC', 247,  # SMALL TILDE
'00AF', 248,  # MACRON
'02D8', 249,  # BREVE
'02D9', 250,  # DOT ABOVE (Mandarin Chinese light tone)
'02DA', 251,  # RING ABOVE
'00B8', 252,  # CEDILLA
'02DD', 253,  # DOUBLE ACUTE ACCENT
'02DB', 254,  # OGONEK
'02C7', 255,  # CARON (Mandarin Chinese third tone)
);
# Table done.

$unicode = '';
$repl = '';
$can = '';

$eb_eval_fromcanon = '';
$eb_eval_tocanon = '';
$eb_nomapC = '';
$eb_nomapA = '';
$eb_mapC = '';
$eb_mapA = '';

#
# Build the eval string for the fromcanon code.
#
# For each 8bit code, we either:
#   1) don't have a character for this code.  So we zap and complain.
#   2) we do know it, so we translate them all at once after we're done
#      with all the ones we don't know.
#
foreach $can (128..255) {
  $unicode = &bib'decimal_to_unicode($can);
  $repl =  pack("C", $can);
  if (defined $umap{$unicode}) {
    $eb_mapC .= $repl;
    $eb_mapA .= pack("C", $umap{$unicode});
  } else {
    $eb_nomapC .= $repl;
    $eb_eval_fromcanon .= "tr/$repl//d && \&bib'gotwarn(\"Can't convert "
                       . &bib'unicode_name($unicode) . " to Apple\");\n";
  }
}
substr($eb_eval_fromcanon,0,0) = "if (/[$eb_nomapC]/) {\n";
$eb_eval_fromcanon .= "}\ntr/$eb_mapC/$eb_mapA/;\n";

#
# Build the eval string for the tocanon code.
#
# nomapA just means there isn't a direct 8bit replacement.  We just insert
# the extended character.
#
foreach $unicode (keys %umap) {
  next if $unicode =~ /^00/;
  $repl = pack("C", $umap{$unicode});
  $eb_nomapA .= $repl;
  $eb_eval_tocanon .= "s/$repl/$bib'cs_ext$unicode/g;\n";
}
substr($eb_eval_tocanon,0,0) = "if (/[$eb_nomapA]/) {\n";
$eb_eval_tocanon .= "}\ntr/$eb_mapA/$eb_mapC/;\n";



#####################

sub tocanon {
  local($_, $protect) = @_;

  &bib'panic("cs-apple tocanon called with no arguments!") unless defined $_;

  eval $eb_eval_tocanon;

  $_;
}

######

sub fromcanon {
  local($_, $protect) = @_;

  &bib'panic("cs-apple fromcanon called with no arguments!") unless defined $_;

  # 8 bit mappings.  This variable is set up at package load time.
  # The algorithm goes as follows:
  #  step 1: Zap and complain about any 8bit characters we don't map.
  #          This is done with a tr/<character>//d for each character.
  #  step 2: Use tr/<canons>/<apples>/ to translate all the two-way
  #          mapped characters right across.
  eval $eb_eval_fromcanon;

  return $_ unless /$bib'cs_escape/o;

  # The standard 7bit map.
  1 while s/${bib'cs_ext}00([0-7].)/pack("C", hex($1))/ge;

  while (/${bib'cs_ext}(....)/) {
    $unicode = $1;
    defined $umap{$unicode}
             && s/${bib'cs_ext}$unicode/pack("C", $umap{$unicode})/ge
             && next;
    &bib'gotwarn("Can't convert ".&bib'unicode_name($unicode)." to Apple");
    s/${bib'cs_ext}$unicode//g;
  }
  while (/${bib'cs_meta}(....)/) {
    $repl = $1;
    &bib'gotwarn("Can't convert ".&bib'meta_name($repl)." to Apple");
    s/${bib'cs_meta}$repl//g;
  }

  $_;
}

#######################
# end of package
#######################

1;
