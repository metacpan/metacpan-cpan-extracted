use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

DBIx::QueryLog->skip_bind(1);

TEST:
subtest 'simple' => sub {
    my $res = capture {
        $dbh->do('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
    };

    like $res, qr/SELECT \* FROM sqlite_master WHERE name = \? : \[foo\]/, 'SQL';
};

subtest 'bind_param' => sub {
    my $res = capture {
        my $sth = $dbh->prepare('SELECT * FROM sqlite_master WHERE name = ?');
        $sth->bind_param(1, 'foo');
        $sth->execute;
    };

    like $res, qr/SELECT \* FROM sqlite_master WHERE name = \? : \[foo\]/, 'SQL';
};

DBIx::QueryLog->skip_bind(0);

unless ($ENV{DBIX_QUERYLOG_SKIP_BIND}) {
    # enabled skip_bind
    $ENV{DBIX_QUERYLOG_SKIP_BIND} = 1;
    goto TEST;
}

done_testing;
