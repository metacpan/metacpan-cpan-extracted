use strict;
use warnings;
use lib 't/lib';
use Test::Requires qw(DBD::Pg Test::PostgreSQL);
use Test::More;
use Test::PostgreSQL;
use t::Util;
use DBIx::QueryLog ();
use DBI;

DBIx::QueryLog->skip_bind(1);

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

TEST:
subtest 'do' => sub {
    my $res = capture {
        $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'root');
    };

    like $res, qr/SELECT \* FROM user WHERE User = \? : \[root\]/;
};

subtest 'bind_param' => sub {
    my $res = capture {
        my $sth = $dbh->prepare('SELECT * FROM user WHERE User = ?');
        $sth->bind_param(1, 'root');
        $sth->execute;
    };

    like $res, qr/SELECT \* FROM user WHERE User = \? : \[root\]/;
};

subtest 'bind_param including undefined' => sub {
    my $res = capture {
        my $sth = $dbh->prepare('SELECT * FROM user WHERE User IN (?, ?)');
        $sth->bind_param(1, undef);
        $sth->bind_param(2, 'root');
        $sth->execute;
    };

    like $res, qr/SELECT \* FROM user WHERE User IN \(\?, \?\) : \[NULL, root\]/;
};

DBIx::QueryLog->skip_bind(0);

unless ($ENV{DBIX_QUERYLOG_SKIP_BIND}) {
    # enabled skip_bind
    $ENV{DBIX_QUERYLOG_SKIP_BIND} = 1;
    goto TEST;
}

done_testing;
