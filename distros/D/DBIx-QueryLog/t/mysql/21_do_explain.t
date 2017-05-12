use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use Test::mysqld;
use t::Util;
use DBIx::QueryLog ();
use DBI;

DBIx::QueryLog->explain(1);

my $mysqld = t::Util->setup_mysqld
    or plan skip_all => $Test::mysqld::errstr || 'failed setup_mysqld';

my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'mysql'), '', '',
    {
        AutoCommit => 1,
        RaiseError => 1,
    },
) or die $DBI::errstr;

my $regex = do {
    my $sth = $dbh->prepare('EXPLAIN SELECT * FROM user WHERE User = ?');
    $sth->bind_param(1, 'root');
    $sth->execute;

    join '\s+\|\s+', @{$sth->{NAME}};
};

DBIx::QueryLog->begin;

TEST:
subtest 'do' => sub {
    my $res = capture {
        $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'root');
    };

    like $res, qr/$regex/;
};

subtest 'execute' => sub {
    my $res = capture {
        my $sth = $dbh->prepare('SELECT * FROM user WHERE User = ?');
        $sth->bind_param(1, 'root');
        $sth->execute;
    };

    like $res, qr/$regex/;
};

for my $method (qw/selectrow_array selectrow_arrayref selectall_arrayref/) {
    subtest $method => sub {
        my $res = capture {
            $dbh->$method(
                'SELECT * FROM user WHERE User = ?', undef, 'root'
            );
        };

        like $res, qr/$regex/;
    };
}

subtest 'logger' => sub {
    DBIx::QueryLog->logger(t::Util->new_logger);

    my $res = capture_logger {
        $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'root');
    };

    ok exists $res->{explain}, 'explain is exists';

    DBIx::QueryLog->logger(undef);
};

subtest 'output' => sub {
    my %params;
    local $DBIx::QueryLog::OUTPUT = sub { %params = @_ };

    $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'root');

    ok exists $params{explain}, 'explain is exists';
};

subtest 'with comment' => sub {
    my $res = capture {
        $dbh->do(<<SQL, undef, 'root');
/* comment1 /* */ /* comment2 */
SELECT /* comment3 */ * /* comment4 /* */
FROM
user WHERE User = ? /* comment5 */
SQL
    };

    like $res, qr/$regex/;
};

subtest 'another SELECT statement into comment' => sub {
    my $res = capture {
        $dbh->do('/* SELECT * FROM foo WHERE bar = "baz" */ SELECT * FROM user WHERE User = ?', undef, 'root');
    };

    like $res, qr/$regex/;
};

subtest 'select only' => sub {
    my $res = capture {
        $dbh->do('CREATE TEMPORARY TABLE __explain(id int)');
        $dbh->do('INSERT INTO __explain VALUES (1),(2),(3)');
        $dbh->do('UPDATE __explain SET id = 0');
        $dbh->do('DELETE FROM __explain');
        $dbh->do('DROP TABLE __explain');
    };

    unlike $res, qr/$regex/;
};

subtest 'found_rows' => sub {
    my $found_rows;
    my $res = capture {
        $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'root');
        $found_rows = $dbh->selectrow_array('SELECT FOUND_ROWS()');
    };

    cmp_ok $found_rows, '>', 0;
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
