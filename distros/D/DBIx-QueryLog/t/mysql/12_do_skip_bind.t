use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use Test::mysqld;
use t::Util;
use DBIx::QueryLog ();
use DBI;

DBIx::QueryLog->skip_bind(1);

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

DBIx::QueryLog->skip_bind(0);

unless ($ENV{DBIX_QUERYLOG_SKIP_BIND}) {
    # enabled skip_bind
    $ENV{DBIX_QUERYLOG_SKIP_BIND} = 1;
    goto TEST;
}

done_testing;
