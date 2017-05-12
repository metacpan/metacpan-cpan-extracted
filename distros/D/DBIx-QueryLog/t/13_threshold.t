use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

sub test_threshold {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($is_enabled, $desc) = @_;

    subtest $desc => sub {
        my $res = capture {
            $dbh->do('SELECT * FROM sqlite_master');
        };

        if ($is_enabled) {
            is $res, undef;
        }
        else {
            isnt $res, undef;
        }
    };
}

DBIx::QueryLog->threshold(1);
test_threshold(1, 'threshold 1');

DBIx::QueryLog->threshold(0);
test_threshold(0, 'disabled threshold');

$ENV{DBIX_QUERYLOG_THRESHOLD} = 1;
test_threshold(1, 'threshold from ENV');

done_testing;
