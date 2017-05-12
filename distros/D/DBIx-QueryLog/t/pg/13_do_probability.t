use strict;
use warnings;
use Test::Requires qw(DBD::Pg Test::PostgreSQL);
use Test::More;
use Test::PostgreSQL;
use t::Util;
use DBIx::QueryLog ();
use DBI;

DBIx::QueryLog->probability(10);

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

sub test_probability {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($is_enabled, $desc) = @_;

    subtest "[$is_enabled]: $desc" => sub {
        my $count = 0;
        for (1..100) {
            my $res = capture {
                $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'root');
            };
            $count++ if $res;
        }

        if ($is_enabled) {
            cmp_ok $count, '<', 100;
        }
        else {
            is $count, 100, $desc;
        }
    };
}

DBIx::QueryLog->probability(10);
test_probability(1, 'probability 10');

DBIx::QueryLog->probability(0);
test_probability(0, 'dsabiled probability');

$ENV{DBIX_QUERYLOG_PROBABILITY} = 10;
test_probability(1, 'probability from ENV');

undef $dbh; # postgresql can't stop gracefully.

done_testing;
