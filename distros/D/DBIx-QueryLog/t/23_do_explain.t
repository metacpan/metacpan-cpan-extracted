use strict;
use warnings;
use Test::Requires qw(DBD::SQLite);
use Test::More;
use t::Util;
use DBIx::QueryLog ();

DBIx::QueryLog->explain(1);

my $dbh = t::Util->new_dbh;

my $regex = do {
    my $sth = $dbh->prepare('EXPLAIN QUERY PLAN SELECT * FROM sqlite_master');
    $sth->execute;

    join '\s+\|\s+', @{$sth->{NAME}};
};

DBIx::QueryLog->begin;

TEST:
subtest do => sub {
    my $res = capture {
        $dbh->do('SELECT * FROM sqlite_master');
    };

    like $res, qr/$regex/;
};

subtest execute => sub {
    my $res = capture {
        my $sth = $dbh->prepare('SELECT * FROM sqlite_master');
        $sth->execute;
    };

    like $res, qr/$regex/;
};

for my $method (qw/selectrow_array selectrow_arrayref selectall_arrayref/) {
    subtest $method => sub {
        my $res = capture {
            $dbh->$method('SELECT * FROM sqlite_master');
        };

        like $res, qr/$regex/;
    };
}

subtest logger => sub {
    DBIx::QueryLog->logger(t::Util->new_logger);

    my $res = capture_logger {
        $dbh->do('SELECT * FROM sqlite_master');
    };

    ok exists $res->{explain}, 'explain is exists';

    DBIx::QueryLog->logger(undef);
};

subtest output => sub {
    my %params;
    local $DBIx::QueryLog::OUTPUT = sub { %params = @_ };

    $dbh->do('SELECT * FROM sqlite_master');

    ok exists $params{explain}, 'explain is exists';
};

subtest 'statement error' => sub {
    my %params;
    local $DBIx::QueryLog::OUTPUT = sub { %params = @_ };
    local $dbh->{PrintError} = 0;

    eval { $dbh->do('HOGE FUGA') };
    ok $DBI::err, 'throw error';
    ok !exists $params{explain}, 'explain is not exists';
};

DBIx::QueryLog->explain(0);

unless ($ENV{DBIX_QUERYLOG_EXPLAIN}) {
    # enabled skip_bind
    $ENV{DBIX_QUERYLOG_EXPLAIN} = 1;
    goto TEST;
}

done_testing;
