#
# bibliography package for Perl
#
# HTML character set.
#
# This uses the HTML 2.0 spec, as described in
#   http://www.w3.org/hypertext/WWW/MarkUp/html-spec/html-spec_toc.html
# specifically,
#   http://www.w3.org/hypertext/WWW/MarkUp/html-spec/html-spec_5.html#SEC5.7
# and
#   http://www.w3.org/hypertext/WWW/MarkUp/html-spec/html-spec_9.html#SEC9.7
#
# At some point I will either make an html3 charset or add it as an option
# to this one.  References for those characters may be found in
#   http://www.w3.org/hypertext/WWW/MarkUp/html3/mathsym.html
# Also see
#   http://www.to.icl.fi/~aj/html3_test/entities.html
#
# Big additions in HTML3 include the greek characters and proper typesetting
# spaces.
#
# As referenced in:
#   http://www.acl.lanl.gov/HTML_WG/html-wg-96q1.messages/0102.html
# I am going to allow the &U+xxxx; form for unicode characters for HTML 3.
# I'm not sure if this is going to stay in the standard however.
#
# Specifically, I use the named references as opposed to the numeric, as that
# is recommended in the html3 draft spec, and it is much easier to read.
# Reading through the working notes of the HTML_WG, it looks like they
# specifically recommend translating Numerical Character Entities of Latin-1
# into the real things.  See reference:
#   http://www.acl.lanl.gov/HTML_WG/html-wg-95q1.messages/0920.html
# about the can of worms this opens.  Specifically, &215; refers to _different_
# characters depending on which ISO 8859-x group you're working with!  The
# worst part of it is that netscape understands all the NCEs but skips most
# of their names!
#
# For this last reason (many browsers don't properly handle named entities),
# I've decided to stay with ISO-8859-1 8bit characters.
#
# This really ought to be called cs-html-8859-1 or something similar, since
# we're doing all our characters as ISO-8859-1.  What we really ought to
# do is seperate all the named entities and meta characters out from the
# actual encoded characters, then have a setting for the particular
# encoding.  One really ought to look at:
#   http://www.ics.uci.edu/pub/ietf/html/draft-ietf-html-i18n-03.txt
# But I'm not going to worry about it at the moment.
#
# XXXXX Todo: handle previous fonts in a more sane fashion.
#
# Dana Jacobsen (dana@acm.org)
# 5 July 1995 (last modified 17 March 1996)

package bp_cs_html;

######

$bib'charsets{'html', 'i_name'} = 'html';

$bib'charsets{'html', 'tocanon'}   = "bp_cs_html'tocanon";
$bib'charsets{'html', 'fromcanon'} = "bp_cs_html'fromcanon";

# This is a regex to search for.  If it succeeds, then we call the routine.
# otherwise not.  If it is set to undef, the routine is always called.
$bib'charsets{'html', 'toesc'}   = "[<\&]";
$bib'charsets{'html', 'fromesc'} = "[\&<>]|${bib'cs_ext}|${bib'cs_meta}";

######

#
# If you want HTML 3 characters
#
$opt_html3 = 0;

# Extra things like sub and sup.
$opt_htmlplus = 1;

$cs_init    = 0;
$cs_to_init = 0;
$cs_fr_init = 0;


######

sub init_cs {


# These mappings are two way.  They get evaluated _after_ entitynames.

# HTML 2.0 characters and the Unicode equivalent
%charmap_2 = (
'0110',	'Dstrok',
'00A6',	'brkbar',
);

# HTML 3.0 characters and the Unicode equivalent
%charmap_3 = (
);

# HTML 2.0 markup and the bp-meta equivalent
%metamap_2 = (
'0102', 'I',
'0103', 'B',
'0104', 'TT',
'0112', '/I',
'0113', '/B',
'0114', '/TT',
'1100', 'P',
'1101', 'PRE',
'1102', 'ADDRESS',
'1103', 'BLOCKQUOTE',
'1110', '/P',
'1111', '/PRE',
'1112', '/ADDRESS',
'1113', '/BLOCKQUOTE',
'1300', 'LI',
'1301', 'UL',
'1311', '/UL',
'1302', 'OL',
'1312', '/OL',
'2100', 'CITE',
'2101', 'EM',
'2102', 'VAR',
'2103', 'STRONG',
'2104', 'CODE',
'2105', 'KBD',
'2106', 'SAMP',
'2110', '/CITE',
'2111', '/EM',
'2112', '/VAR',
'2113', '/STRONG',
'2114', '/CODE',
'2115', '/KBD',
'2116', '/SAMP',
);

# HTML+ markup and the bp-meta equivalent
%metamap_p = (
'0302',	'SUP',
'0312',	'SUB',
'030F',	'/SUP',
'031F',	'/SUB',
);

# HTML 3.0 markup and the bp-meta equivalent
%metamap_3 = (
'0200',	'BIG',
'020F',	'/BIG',
'0210', 'SMALL',
'021F', '/SMALL',
);

  $cs_init = 1;
}

sub init_cs_fr {

  &init_cs unless $cs_init;

  # XXXXX We should just use unicode_approx.
  # Map various unicode entities to our stuff.
  %charmap_from = (
  '2212', '-',
  '2013', '--',
  '2014', '---',
  '2002', ' ',    # These two are probably wrong.
  '2003', '  ',
  );

  # HTML 2.0 Secondary meta mappings for fromcanon
  # Note that these do _not_ get wrapped in <> like metamap_2 does.
  %metafrs_2 = (
  '2200',	'<A ',
  '2210',	'</A>',
  '2300',	'href="',
  '2310',	'">',
  );

  $cs_fr_init = 1;
}

sub init_cs_to {
  local($f);

  &init_cs unless $cs_init;

  # HTML 2.0 entity names that map to ISO-8859-1 codes.
  # This is used in tocanon only.  We leave the rest in 8 bits because it
  # seems every browser can display that, but many of them don't map the names.

  %entitynames = (
  'nbsp',	160,
  'iexcl',	161,
  'cent',	162,
  'pound',	163,
  'curren',	164,
  'yen',	165,
  'brvbar',	166,
  'sect',	167,
  'uml',	168,
  'copy',	169,
  'ordf',	170,
  'laquo',	171,
  'not',	172,
  'shy',	173,
  'reg',	174,
  'hibar',	175,
  'deg',	176,
  'plusmn',	177,
  'sup2',	178,
  'sup3',	179,
  'acute',	180,
  'micro',	181,
  'para',	182,
  'middot',	183,
  'cedil',	184,
  'sup1',	185,
  'ordm',	186,
  'raquo',	187,
  'frac14',	188,
  'frac12',	189,
  'frac34',	190,
  'iquest',	191,
  'Agrave',	192,
  'Aacute',	193,
  'Acirc',	194,
  'Atilde',	195,
  'Auml',	196,
  'Aring',	197,
  'AElig',	198,
  'Ccedil',	199,
  'Egrave',	200,
  'Eacute',	201,
  'Ecirc',	202,
  'Euml',	203,
  'Igrave',	204,
  'Iacute',	205,
  'Icirc',	206,
  'Iuml',	207,
  'ETH',	208,
  'Ntilde',	209,
  'Ograve',	210,
  'Oacute',	211,
  'Ocirc',	212,
  'Otilde',	213,
  'Ouml',	214,
  'times',	215,
  'Oslash',	216,
  'Ugrave',	217,
  'Uacute',	218,
  'Ucirc',	219,
  'Uuml',	220,
  'Yacute',	221,
  'THORN',	222,
  'szlig',	223,
  'agrave',	224,
  'aacute',	225,
  'acirc',	226,
  'atilde',	227,
  'auml',	228,
  'aring',	229,
  'aelig',	230,
  'ccedil',	231,
  'egrave',	232,
  'eacute',	233,
  'ecirc',	234,
  'euml',	235,
  'igrave',	236,
  'iacute',	237,
  'icirc',	238,
  'iuml',	239,
  'eth',	240,
  'ntilde',	241,
  'ograve',	242,
  'oacute',	243,
  'ocirc',	244,
  'otilde',	245,
  'ouml',	246,
  'divide',	247,
  'oslash',	248,
  'ugrave',	249,
  'uacute',	250,
  'ucirc',	251,
  'uuml',	252,
  'yacute',	253,
  'thorn',	254,
  'yuml',	255,
  );

  # Construct the backwards map for these unique characters
  foreach $f (keys %metamap_2) {
    $bmetamap_2{$metamap_2{$f}} = $f;
  }

  # HTML 2.0 Secondary meta mappings for tocanon
  %metatos_2 = (
  );

  $cs_to_init = 1;
}


#####################


# Essentially we're ISO-8859-1, but with a few protected characters
# and some extra ones.
# XXX protect lonely & characters

sub tocanon {
  local($_, $protect) = @_;
  local($repl, $can, $mine, $unicode);

  &bib'panic("cs-html tocanon called with no arguments!") unless defined $_;

  # Check to see if we have anything to do.
  return $_ unless /<|\&/;

  # XXXXX Ignore named Latin-1 for now.

  # Handle links first.
  local($link, $text);
  while (/<A\s+href="([^"]+)">(.*)<\/A>/i) {
    ($link, $text) = ($1, $2);
    # Why, oh why, couldn't perl4 have had minimal matching?  I HATE this.
    $text =~ s/<\/A>.*//i;
    s/<A\s+href="$link">$text<\/A>/${bib'cs_meta}2200${bib'cs_meta}2300$link${bib'cs_meta}2310$text${bib'cs_meta}2210/gi;
  }

  # XXXXX Zap these for now
  s/<A[^>]*>//gi;
  s/<BASE[^>]*>//gi;
  s/<\/A>//gi;
  s/<\/?(BODY|HEAD|HTML|TITLE)>//gi;
  s/<\/?H\d[^>]*>//gi;
  s/<IMG[^>]*>//gi;
  s/<(BR|HR)>//gi;

  return $_ unless /<|\&/;

  &init_cs_to unless $cs_to_init;

  # XXXXX  We've got two ways we can approach this:
  #
  #	   1) we can assume that special characters are rare, so we just
  #           walk through our maps in some sort of liklihood order, trying
  #           to replace things.  We should run lots of tests only rarely.
  #        2) we can assume that special characters are likely, so we want
  #           to loop over the characters in the string.  That means we have
  #           to have both a forward and a backward map.  More memory and more
  #           startup time are traded for increased performance.
  #
  #        Which approach should we use?  Maybe it depends on the charset?
  #
  #        I'm taking a hybrid approach.  Method 1 for HTML3 and HTML+.  M2
  #        for meta strings (<...>).  M2 for standard escapes, and it gets
  #        more complicated from there.

  if ($opt_html3) {
    while (($can, $mine) = each %metamap_3) {
      $mine =~ s/(\W)/\\$1/g;
      s/<$mine>/${bib'cs_meta}$can/g;
    }
  }
  if ($opt_htmlplus) {
    while (($can, $mine) = each %metamap_p) {
      $mine =~ s/(\W)/\\$1/g;
      s/<$mine>/${bib'cs_meta}$can/g;
    }
  }
  while (/<(\S[^>]*)>/) {
    $repl = $1;
    # added uc() to support lower-case HTML tags (ptandler, 02-03-24)
    defined $bmetamap_2{uc($repl)} && s/<$repl>/${bib'cs_meta}$bmetamap_2{uc($repl)}/g
                               && next;

    &bib'gotwarn("Unknown HTML markup: <$repl>");
    s/<$repl>//g;
  }

  $_ = &bib'font_check($_) if /${bib'cs_meta}01/o;

  # Convert html escapes for ISO-8859-1 things to standard form.
  s/&lt;/</g;
  s/&gt;/>/g;
  s/&quot;/"/g;
  # To prevent matching this, we leave it in extended format.
  s/&amp;/${bib'cs_ext}0026/go;

  # always check to see if we have any characters left to change
  return $_  unless /\&/;

  # This should handle 8 bit chars correctly as well as the new UCS-2, cf.
  #   <http://www.ics.uci.edu/pub/ietf/html/draft-ietf-html-i18n-03.txt>
  while (/\&#(\d+);/) {
    $repl = $1;
    $can = &bib'unicode_to_canon(  &bib'decimal_to_unicode($repl)  );
    s/\&#$repl;/$can/g;
  }
  # This handles to the new &U+xxx; form.  I need to find a good reference
  # for this.
  while (/\&U\+([\dA-Fa-f]{4});/) {
    $repl = $1;
    $can = &bib'unicode_to_canon( $repl );
    s/\&U\+$repl;/$can/g;
  }

  # Now for the named entities.

  while (/\&(\S*);/) {
    $repl = $1;
    $repl =~ s/(\W)/\\$1/g;
    if (defined $entitynames{$repl}) {
      $can = pack("C", $entitynames{$repl});
      s/\&$repl;/$can/g;
      next;
    }
    # We now search through the charmaps to see if they contain our character.
    # Terribly inefficient, but we shouldn't be doing this often.
    if (defined $opt_html3) {
      $can = undef;
      foreach $unicode (keys %charmap_3) {
        next unless $charmap_3{$unicode} eq $repl;
        # only here if we found the map.
        $can = &bib'unicode_to_canon($unicode);
        s/\&$repl;/$can/g;
        last;
      }
      next if defined $can;
    }
    $can = undef;
    foreach $unicode (keys %charmap_2) {
      next unless $charmap_2{$unicode} eq $repl;
      # only here if we found the map.
      $can = &bib'unicode_to_canon($unicode);
      s/\&$repl;/$can/g;
      last;
    }
    next if defined $can;

    &bib'gotwarn("Unknown HTML entity: \&$repl; : in $_");
    s/\&$repl;//g;
  }
  s/&(\s)/${bib'cs_ext}0026$1/g;

  return $_  unless /\&/;

  &bib'gotwarn("Unknown HTML characters in '$_'");

  $_;
}

######

sub fromcanon {
  local($_, $protect) = @_;
  local($repl, $can);

  &bib'panic("cs-html fromcanon called with no arguments!") unless defined $_;

  # Leave 8bit characters alone since we're assuming ISO-8859-1 HTML.

  #1 while s/${bib'cs_ext}(00..)/&bib'unicode_to_canon($1)/ge;

  # XXXXX  I think these should go here, as they create a mess if they go
  #        after the ext and meta maps.

  s/\&/\&amp;/g;
  s/</\&lt;/g;
  s/>/\&gt;/g;
  s/${bib'cs_ext}0026/\&amp;/go;

  return $_ unless /$bib'cs_escape/o;

  &init_cs_fr unless $cs_fr_init;

  # Extension characters
  while (/${bib'cs_ext}(....)/o) {
    $repl = $1;
    if ($repl =~ /^00/) {   # The 8bit mapping is the same
      1 while s/${bib'cs_ext}00(..)/pack("C", hex($1))/goe;
      next;
    }
    $opt_html3 && defined $charmap_3{$repl}
               && s/$bib'cs_ext$repl/\&$charmap_3{$repl};/g
               && next;
    defined $charmap_2{$repl}
               && s/$bib'cs_ext$repl/\&$charmap_2{$repl};/g
               && next;
    defined $charmap_from{$repl}
               && s/$bib'cs_ext$repl/$charmap_from{$repl}/g
               && next;

    $opt_html3  &&  s/$bib'cs_ext$repl/\&U\+$repl;/g  &&  next;

    $can = &bib'unicode_approx($repl);
    defined $can  &&  s/$bib'cs_ext$repl/$can/g  &&  next;

    &bib'gotwarn("Can't convert ".&bib'unicode_name($repl)." to HTML");
    s/${bib'cs_ext}$repl//g;
  }

  # XXXXX We need to deal with font changes.
  $_ = &bib'font_noprev($_) if /${bib'cs_meta}0110/o;

  while (/${bib'cs_meta}(....)/o) {
    $repl = $1;
    # We need to do these in order of most to least inclusive.
    # That way we can get, say ThinSpace to map to a thin space in HTML3
    # and a space in HTML2.
    $opt_html3    && defined $metamap_3{$repl}
                  && s/${bib'cs_meta}$repl/<$metamap_3{$repl}>/g
                  && next;
    $opt_htmlplus && defined $metamap_p{$repl}
                  && s/${bib'cs_meta}$repl/<$metamap_p{$repl}>/g
                  && next;
    defined $metamap_2{$repl}
                  && s/${bib'cs_meta}$repl/<$metamap_2{$repl}>/g
                  && next;
    defined $metafrs_2{$repl}
                  && s/${bib'cs_meta}$repl/$metafrs_2{$repl}/g
                  && next;

    $can = &bib'meta_approx($repl);
    defined $can  &&  s/$bib'cs_meta$repl/$can/g  &&  next;

    &bib'gotwarn("Can't convert ".&bib'meta_name($repl)." to HTML");
    s/${bib'cs_meta}$repl//g;
  }

  $_;
}

#######################
# end of package
#######################

1;
