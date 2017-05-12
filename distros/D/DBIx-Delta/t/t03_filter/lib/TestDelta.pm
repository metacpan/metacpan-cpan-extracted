package TestDelta;
use DBI;
use base qw(DBIx::Delta);
sub connect {
  DBI->connect("dbi:SQLite:dbname=$ENV{TEST_DELTA_DB}",'','');
}
sub filter_statement {
  my ($self, $statement) = @_;
  $statement =~ s/^(grant\b.*)\blocalhost/${1}192.168.0.10/;
  return $statement;
}
1;
