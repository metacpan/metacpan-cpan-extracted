# $Id$

use strict;


# unit tests for parse_dsn

use Test::More tests => 1;

use CGI::Session;
my $s = CGI::Session->new();

is_deeply($s->parse_dsn('DR:FILE'), 
  { driver => 'file'}, 
  "parse_dsn: abbreviation and lower-casing");

$s->delete();
