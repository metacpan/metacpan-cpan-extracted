use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

sub test_probability {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($is_enabled, $desc) = @_;

    subtest "[$is_enabled]: $desc" => sub {
        my $count = 0;
        for (1..100) {
            my $res = capture {
                $dbh->do('SELECT * FROM sqlite_master');
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
