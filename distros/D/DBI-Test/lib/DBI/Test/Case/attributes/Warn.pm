use strict;
use warnings;
use Test::More;

our @DB_CREDS = ('dbi:SQLite::memory:', undef, undef, { AutoCommit => 0});
my %SQLS = (
  'SELECT' => 'SELECT 1+1',
  'INSERT' => undef
);

{ #Check that warn is enabled by default
  
  my $dbh = DBI->connect( @DB_CREDS[0..2], {} );
  isa_ok($dbh, 'DBI::db');
  ok($dbh->{Warn}, '$dbh->{Warn} is true');
  ok($dbh->FETCH('Warn'), '$dbh->FETCH(Warn) is true');
}

done_testing();