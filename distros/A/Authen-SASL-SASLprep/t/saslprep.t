# $Id$

use strict;
use utf8;

use Test::More;
use Test::NoWarnings;

use Authen::SASL::SASLprep;

our @strprep = (

  # test vectors from RFC 4013, section 3.
  #

  [ "I\x{00AD}X",       'IX',		'SOFT HYPHEN mapped to nothing' ],
  [ 'user',             'user',		'no transformation' ],
  [ 'USER',             'USER',		'case preserved, will not match #2' ],
  [ "\x{00AA}",         'a',		'output is NFKC, input in ISO 8859-1' ],
  [ "\x{2168}",         'IX',		'output is NFKC, will match #1' ],
  [ "\x{0007}",         undef,		'Error - prohibited character' ],
  [ "\x{0627}\x{0031}", undef,		'Error - bidirectional check' ],

  # some more tests
  #

  [ 'ÄÖÜß',		'ÄÖÜß',		'German umlaut case preserved' ],
  [ 'äöüß',		'äöüß',		'German umlaut case preserved' ],
  [ "\x{A0}",		' ',		'no-break space mapped to ASCII space' ],
  [ "\x{2009}",		' ',		'thin space mapped to ASCII space' ],
  [ "\x{3000}",		' ',		'ideographic space mapped to ASCII space' ],
  [ "\x{A0}\x{2009}\x{3000}", '   ',	'no space collapsing' ],

  # newly assigned in Unicode 3.2
  #
  [ "\x{2047}", 	"??",		'Double question mark (added in Unicode 3.2)' ],
  [ "\x{30FF}", 	"コト",		'Katakana digraph koto (added in Unicode 3.2)' ],
  [ "M&\x{20B0}", 	"M&\x{20B0}",	'German penny sign (added in Unicode 3.2)' ],

  # unassigned in 3.2
  #
  [ "I\x{0221}", 	"I\x{0221}",	'Latin small letter d with curl (added in Unicode 4.0)', 1 ],
  [ "\x{33FF}", 	"\x{33FF}",	'Square gal (added in Unicode 4.0, would decompose)', 1 ],
  [ "\x{1F23B}", 	"\x{1F23B}",	'Squared CJK unified (added in Unicode 9.0, would decompose)', 1 ],
  [ "\x{E01F8}", 	"\x{E01F8}",	'U+E01F8 (unassigned as of Unicode 9.0)', 1 ],
);

plan tests => ($#strprep+1)*3 + 1;

foreach my $test (@strprep) 
{
  my ($in,$out,$comment,$has_unassigned) = @{$test};

  is(eval{saslprep($in)}, $out, $comment);
  is(eval{saslprep($in,0)}, $out, $comment.' (query)');
  $out = undef if $has_unassigned;
  is(eval{saslprep($in,1)}, $out, $comment.' (stored)');
}
