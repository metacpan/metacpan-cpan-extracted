use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use Test::mysqld;
use t::Util;
use DBIx::QueryLog ();
use DBI;

DBIx::QueryLog->probability(10);

my $mysqld = t::Util->setup_mysqld
    or plan skip_all => $Test::mysqld::errstr || 'failed setup_mysqld';

my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'mysql'), '', '',
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

done_testing;
