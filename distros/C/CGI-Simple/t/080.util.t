use Test::More tests => 58;
use strict;

use CGI::Simple::Util qw(escape unescape);

# ASCII order, ASCII codepoints, ASCII repertoire

my %punct = (
  ' '  => '20',
  '!'  => '21',
  '"'  => '22',
  '#'  => '23',
  '$'  => '24',
  '%'  => '25',
  '&'  => '26',
  '\'' => '27',
  '('  => '28',
  ')'  => '29',
  '*'  => '2A',
  '+'  => '2B',
  ','  => '2C',
  # '-' => '2D',  '.' => '2E'
  '/'  => '2F',
  ':'  => '3A',
  ';'  => '3B',
  '<'  => '3C',
  '='  => '3D',
  '>'  => '3E',
  '?'  => '3F',
  '['  => '5B',
  '\\' => '5C',
  ']'  => '5D',
  '^'  => '5E',
  # '_' => '5F',
  '`' => '60',
  '{' => '7B',
  '|' => '7C',
  '}' => '7D',
  '~' => '7E',
);

# The sort order may not be ASCII on EBCDIC machines:

foreach ( sort( keys( %punct ) ) ) {
  my $escape     = "AbC\%$punct{$_}dEF";
  my $cgi_escape = escape( "AbC$_" . "dEF" );
  is( $escape, $cgi_escape, "$escape ne $cgi_escape" );
  my $unescape     = "AbC$_" . "dEF";
  my $cgi_unescape = unescape( "AbC\%$punct{$_}dEF" );
  is( $unescape, $cgi_unescape, "$unescape ne $cgi_unescape" );
}

