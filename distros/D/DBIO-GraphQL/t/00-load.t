use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
  use_ok('DBIO::GraphQL') || print "Bail out!\n";
}

diag("Testing DBIO::GraphQL, Perl $], $^X");
