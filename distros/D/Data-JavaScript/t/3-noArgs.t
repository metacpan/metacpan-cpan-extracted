#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;
use Test2::Require::Perl 'v5.7';

use Data::JavaScript;

#Test undef default
is join( q//, jsdump( 'foo', [ 1, undef, 1 ] ) ),
  'var foo = new Array;foo[0] = 1;foo[1] = undefined;foo[2] = 1;',
  'Default undef';

#Test alphanumeric string output: quoting, ASCII/ANSI escaping, Unicode
## no critic (ProhibitEscapedCharacters, RequireInterpolationOfMetachars)
is join( q//, jsdump( 'ANSI', "M\xF6tley Cr\xFce" ) ),
  'var ANSI = "M\xF6tley Cr\xFCe";',
  'Quoting, ASCII/ANSI escaping, unicode';

is join( q//, jsdump( 'unicode', "Euros (\x{20ac}) aren't Ecus (\x{20a0})" ) ),
  q(var unicode = "Euros (\u20AC) aren't Ecus (\u20A0)";),
  q(Wide characters);

is join( q//, jsdump( 'Cherokee', "\x{13E3}\x{13E3}\x{13E3}" ) ),
  q(var Cherokee = "\u13E3\u13E3\u13E3";),
  'Non-Latin characters';

done_testing;
