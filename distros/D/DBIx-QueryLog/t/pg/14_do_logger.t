use strict;
use warnings;
use Test::Requires qw(DBD::Pg Test::PostgreSQL);
use Test::More;
use Test::PostgreSQL;
use t::Util;
use DBIx::QueryLog ();
use DBI;

DBIx::QueryLog->logger(t::Util->new_logger);

my $pg = t::Util->setup_postgresql
    or plan skip_all => $Test::PostgreSQL::errstr || 'failed setup_postgresql';

my $dbh = DBI->connect(
    $pg->dsn(dbname => 'test'), '', '',
    {
        AutoCommit => 1,
        RaiseError => 1,
    },
) or die $DBI::errstr;

DBIx::QueryLog->begin;

my $res = capture_logger {
    $dbh->do('SELECT * FROM user');
}; 

is $res->{sql}, 'SELECT * FROM user', 'query ok';

delete $res->{dbh}; # cycle ref!!!!! That's why postgresql can't stop gracefully.

done_testing;
