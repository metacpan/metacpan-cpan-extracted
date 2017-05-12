#!/usr/bin/perl

require "bptest.pl";

$skiptests = 0;   # to skip early tests during development
$timing = 0;      # to use the same seed for timing tests

#
# This test covers the 8859-1, apple, TeX, troff, and HTML
# character sets.  It also tests the canon<->unicode routines
# from bp-p-utils.pl.
#
# It does not test the 'none' and 'auto' character sets.  The
# auto character set doesn't exist, so it tests all the charsets
# that are currently in bp.
#
# For each charset, we run through an iso string, which contains
# the 8-bit characters 0 through 255.  Before processing, certain
# characters known to not be supported are removed (generally
# 200-237 octal, but sometimes others).  This is to prevent
# excessive warnings and make the tests easier to perform.  We
# run the fromcanon code, then the tocanon code, and check to
# see that the outputs match.
#
# In addition, we do the same thing for a long string of random
# 8-bit characters, with the hope that this will test combinations
# of characters we may not have thought of.
#
# Some formats also test a few special strings that we want to
# test.  These usually are selected by looking at the source
# code for the converter, and checking any seemingly weak points.
#
# Lastly, we run these strings through a loop:
#   88591->can->troff->can->html->can->88591
# and check that they match.  After removing some characters, we try
#   88591->can->troff->can->apple->can->html->can->88591
# 


# Generate a string with each 8bit character.
$isostring = '';
for (0..255) {
  $isostring .= pack("C", $_);
}

# Generate a random string of 8bit characters.  This should
#   be a long string so we test lots of things.
# We do this because although testing the 8bit characters in order
#   should find any problems, certain character combinations can
#   cause problems if the routine isn't written properly.  This may
#   stumble across a combination I didn't think of.
# We must print out the seed if there is an error, so that we can
#   duplicate the string that caused the error.
#
# Argh!  Perl4 coredumps with srand, and Perl5 coredumps with MSRNG.
# I don't know why they crash.  Perl5.002 seems to work with MSRNG.
#
$randstring = '';
$randstringlength = 16385;  # should be at least 8192
$seed = undef;
$seed = 42 if $timing;
if ( ($] >= 5) && ($] < 5.002) ) {
  srand($seed) unless defined $seed;
  $n = 0;
  while ($n++ < $randstringlength) {
    $randstring .= pack("C", int(rand(256)) );
  }
} else {
  if (defined $seed) {
    $seed = &msrand($seed);
  } else {
    $seed = &msrand;
  }
  $n = 0;
  while ($n++ < $randstringlength) {
    $randstring .= pack("C", int(&mrand(256)) );
  }
}
$randstring = $randstring x 5 if $timing;

$cantest = "${bib'cs_ext}0026";


# The character conversion routines assume that the strings will
# already be escaped.  They also do not do any unescaping (except
# for cs_ext and cs_meta, which they are supposed to handle).
$isostring  =~ s/$bib'cs_escape/$bib'cs_char_escape/go;
$randstring =~ s/$bib'cs_escape/$bib'cs_char_escape/go;


print "Testing character set routines, seed=$seed.\n";

if (!$skiptests) {

&begintest("bib'unicode", 12);

&check('', "bib'canon_to_unicode", '006C', 'l');
&check('', "bib'canon_to_unicode", '00C4', "\304");
&check('', "bib'canon_to_unicode", 'A1C6', "${bib'cs_ext}A1c6");
&check('', "bib'canon_to_unicode", '001C', $bib'cs_char_escape);

&check('', "bib'unicode_to_canon", '5', '0035');
&check('', "bib'unicode_to_canon", "\xE9", '00E9');
&check('', "bib'unicode_to_canon", "${bib'cs_ext}CF8A", 'CF8A');

&check('', "bib'decimal_to_unicode", '0023', 35);
&check('', "bib'decimal_to_unicode", '359B', 13723);
&check('', "bib'unicode_to_decimal", 35, '0023');
&check('', "bib'unicode_to_decimal", 13723, '359b');

$f = $failed;
for (0..512) {
  $can = &bib'unicode_to_canon(&bib'decimal_to_unicode($_));
  $val = &bib'unicode_to_decimal(&bib'canon_to_unicode($can));
  &check('nostatus,norun',"unicode loop", $_, $val);
}
$can = $val = undef;
&check('partial', "unicode loop", $f, $failed);

&endtest;

# Test ISO-8859-1

&testcharset("8859-1", 5);

$caniso = $isostring;
&check('', "bp_cs_88591'tocanon", $caniso, $isostring);
&check('', "bp_cs_88591'fromcanon", $isostring, $caniso);
$canran = $randstring;
&check('', "bp_cs_88591'tocanon", $canran, $randstring);
&check('', "bp_cs_88591'fromcanon", $randstring, $canran);

&check('', "bp_cs_88591'fromcanon", '&', $cantest);

&endtest;

# Test Apple

&bib'errors('print');
&testcharset("apple", 5);
# get rid of characters we don't handle.
$c = $caniso;
$c =~ s/[\200-\237\246\255\262\263\271\274\275\276\320\327\335\336\360\375\376]//g;
$appiso = &bp_cs_apple'fromcanon($c);
&check('partial', "apple'fromcanon", 1, 1);
&check('', "bp_cs_apple'tocanon", $c, $appiso);
$c = $appiso = undef;

$c = $canran;
$c =~ s/[\200-\237\246\255\262\263\271\274\275\276\320\327\335\336\360\375\376]//g;
$appran = &bp_cs_apple'fromcanon($c);
&check('partial', "apple'fromcanon", 1, 1);
&check('', "bp_cs_apple'tocanon", $c, $appran);
$c = $appran = undef;

&check('', "bp_cs_apple'fromcanon", '&', $cantest);

&endtest;

# Test troff

&testcharset("troff", 5);

($c = $caniso) =~ s/[\200-\237]//g;  # troff can't handle these
$troiso = &bp_cs_troff'fromcanon($c);
&check('partial', "troff'fromcanon", 1, 1);
&check('', "bp_cs_troff'tocanon", $c, $troiso);
$c = $troiso = undef;

($c = $canran) =~ s/[\200-\237]//g;  # troff can't handle these
$troran = &bp_cs_troff'fromcanon($c);
&check('partial', "troff'fromcanon", 1, 1);
&check('', "bp_cs_troff'tocanon", $c, $troran);
$c = $troran = undef;

&check('', "bp_cs_troff'fromcanon", '&', $cantest);

&endtest;

# Test TeX

&testcharset("tex", 3);
($c = $caniso) =~ s/[\200-\337]//g;  # TeX can't handle these
$texiso = &bp_cs_tex'fromcanon($c, 1);
&check('partial', "tex'fromcanon", 1, 1);
&check('', "bp_cs_tex'tocanon", $c, $texiso, 1);
$c = $texiso = undef;

# XXXXX Fix me!  Something in here is broken.

#($c = $canran) =~ s/[\200-\237]//g;
#$texran = &bp_cs_tex'fromcanon($c, 1);
#&check('partial', "tex'fromcanon", 1, 1);
#&check('', "bp_cs_tex'tocanon", $c, $texran, 1);
#$c = $texran = undef;

&check('', "bp_cs_tex'fromcanon", '&', $cantest);

&endtest;

# Test HTML

&testcharset("html", 7);

&check('', "bp_cs_html'fromcanon", '&amp;', $cantest);
&check('', "bp_cs_html'tocanon", pack("C", 199), '&Ccedil;' );
# This should generate a warning
$oldwlev = $bib'glb_warn_level;
$bib'glb_warn_level = 0;
&check('', "bp_cs_html'tocanon", '', '&fo??o*+?/g;' );
$bib'glb_warn_level = $oldwlev;

$c = $caniso;
$htmiso = &bp_cs_html'fromcanon($c);
&check('partial', "html'fromcanon", 1, 1);
$t = &bp_cs_html'tocanon($htmiso);
$t =~ s/${bib'cs_ext}0026/&/g;  # html leaves & characters in extended form.
&check('norun', "bp_cs_html'tocanon", $c, $t);
$c = $htmiso = $t = undef;

$c = $canran;
$htmran = &bp_cs_html'fromcanon($c);
&check('partial', "html'fromcanon", 1, 1);
$t = &bp_cs_html'tocanon($htmran);
$t =~ s/${bib'cs_ext}0026/&/g;  # html leaves & characters in extended form.
&check('norun', "bp_cs_html'tocanon", $c, $t);
$c = $htmran = $t = undef;

&endtest;

} else {  # end of skipped tests
  &bib'load_charset('8859-1');
  &bib'load_charset('apple');
  &bib'load_charset('troff');
  &bib'load_charset('html');
}

# Test troff / HTML / 8859-1 loop

&begintest("cs conversion loops", 5);

$f = $failed;
for $iso ( "\000" .. "\377" ) {
  next if $iso =~ /[\200-\237]/;
  $can = &bp_cs_88591'tocanon($iso);
  $imd = &bp_cs_troff'fromcanon($can);
  $can = &bp_cs_troff'tocanon($imd);
  $imd = &bp_cs_html'fromcanon($can);
  $can = &bp_cs_html'tocanon($imd);
  $isr = &bp_cs_88591'fromcanon($can);
  &check('nostatus,norun', "cs conversion loop ".ord($iso), $iso, $isr);
}
$can = $imd = $isr = undef;
&check('partial', "cs conversion loop", $f, $failed);

$can = &bp_cs_88591'tocanon($isostring);
$imd = &bp_cs_html'fromcanon($can);
$can = &bp_cs_html'tocanon($imd);
$isr = &bp_cs_88591'fromcanon($can);
&check('norun', "iso conversion loop 1", $isostring, $isr);
$can = $imd = $isr = undef;

($iso = $isostring) =~ s/[\200-\237]//g;
$can = &bp_cs_88591'tocanon($iso);
$imd = &bp_cs_troff'fromcanon($can);
$can = &bp_cs_troff'tocanon($imd);
$imd = &bp_cs_html'fromcanon($can);
$can = &bp_cs_html'tocanon($imd);
$isr = &bp_cs_88591'fromcanon($can);
&check('norun', "iso conversion loop 2", $iso, $isr);
$can = $imd = $isr = undef;  # leave $iso

$iso =~ s/[\200-\237\246\255\262\263\271\274\275\276\320\327\335\336\360\375\376]//g;
$can = &bp_cs_88591'tocanon($iso);
$imd = &bp_cs_troff'fromcanon($can);
$can = &bp_cs_troff'tocanon($imd);
$imd = &bp_cs_apple'fromcanon($can);
$can = &bp_cs_apple'tocanon($imd);
$imd = &bp_cs_html'fromcanon($can);
$can = &bp_cs_html'tocanon($imd);
$isr = &bp_cs_88591'fromcanon($can);
&check('norun', "iso conversion loop 3", $iso, $isr);
$can = $imd = $isr = $iso = undef;

$can = &bp_cs_88591'tocanon($randstring);
$imd = &bp_cs_html'fromcanon($can);
$can = &bp_cs_html'tocanon($imd);
$rnr = &bp_cs_88591'fromcanon($can);
&check('norun', "random conversion loop 1", $randstring, $rnr);
$can = $imd = $rnr = undef;

&endtest;

&bib'load_charset("html");
# We need an options routine for charsets...
$bp_cs_html'opt_html3 = 1;
&begintest("HTML 3", 4);

&check('', "bp_cs_html'tocanon", pack("C", 222), '&THORN;' );
&check('', "bp_cs_html'tocanon", pack("C", 165), '&#165;' );
&check('', "bp_cs_html'tocanon", "${bib'cs_ext}AB7F", '&U+AB7F;' );
&check('', "bp_cs_html'fromcanon", '&U+AB7F;', "${bib'cs_ext}AB7F" );

&endtest;
