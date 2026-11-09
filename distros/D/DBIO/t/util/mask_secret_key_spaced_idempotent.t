# ABSTRACT: a mask that stands is left standing, also behind 'key = ' with whitespace (karr k392)
use strict;
use warnings;

use Test::More;
use DBIO::Util qw(mask_connect_secrets mask_statement_secrets);

for my $text (
  'PRAGMA key = ***',
  'password = ***',
  "PRAGMA key  =  ***;",
  'SELECT key( *** )',
) {
  is mask_connect_secrets($text), $text, "idempotent: $text";
  is mask_connect_secrets($text, [ undef, undef, 'unrelated' ]), $text, "unrelated password: $text";
}

is mask_statement_secrets("PRAGMA key = 'abc'", "PRAGMA key = 'abc'"), 'PRAGMA key = ***',
  'a statement with a spaced key shows one mask';

done_testing;
