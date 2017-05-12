use Test::More tests => 5;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 4
	unless $db;

  my $dbh = open_db();

  ok($dbh->do('DROP TABLE dbixtest1'), "Drop table 1")
    or diag $dbh->errstr;
  ok($dbh->do('DROP TABLE dbixtest2'), "Drop table 2")
    or diag $dbh->errstr;

  close_db();

}
