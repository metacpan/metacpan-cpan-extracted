use strict;
use warnings;
use Test::Requires qw(DBD::Pg Test::PostgreSQL);
use Test::More;
use Test::PostgreSQL;
use t::Util;
use DBIx::QueryLog ();
use DBI;

DBIx::QueryLog->explain(1);

my $pg = t::Util->setup_postgresql
    or plan skip_all => $Test::PostgreSQL::errstr || 'failed setup_postgresql';

my $dbh = DBI->connect(
    $pg->dsn(dbname => 'test'), '', '',
    {
        AutoCommit => 1,
        RaiseError => 1,
    },
) or die $DBI::errstr;

my $regex = do {
    my $sth = $dbh->prepare('EXPLAIN SELECT * FROM "user" WHERE "User" = ?');
    $sth->bind_param(1, 'root');
    $sth->execute;

    join '\s+\|\s+', @{$sth->{NAME}};
};

DBIx::QueryLog->begin;

TEST:
subtest 'do' => sub {
    my $res = capture {
        $dbh->do('SELECT * FROM "user" WHERE "User" = ?', undef, 'root');
    };

    like $res, qr/$regex/;
};

subtest 'statement error' => sub {
    my %params;
    local $DBIx::QueryLog::OUTPUT = sub { %params = @_ };
    local $dbh->{PrintError} = 0;

    eval { $dbh->do('HOGE FUGA') };
    ok $DBI::err, 'throw error';
    ok !exists $params{explain}, 'explain is not exists';
};

done_testing;
