package TestDelta;
use DBI;
use base qw(DBIx::Delta);
sub connect {
  DBI->connect("dbi:SQLite:dbname=$ENV{TEST_DELTA_DB}");
}
1;
