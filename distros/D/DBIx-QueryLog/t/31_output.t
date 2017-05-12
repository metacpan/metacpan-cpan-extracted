use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;
use File::Temp qw(tempfile);
use IO::Handle;

sub test_params {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($desc, $cb, $bind, %opts) = @_;
    $bind ||= [];

    my %params;
    local $DBIx::QueryLog::OUTPUT = sub { %params = @_ };
    $cb->();

    subtest $desc => sub {
        is $params{level}, 'debug', 'level';
        is_deeply $params{bind_params}, $bind, 'bind_params';

        if ($opts{skip_bind}) {
            is $params{message}, sprintf("[%s] [%s] [%s] %s : [%s] at %s line %s\n",
                @params{qw/localtime pkg time sql/}, join(',', @{$params{bind_params}}),
                @params{qw/file line/},
            ), 'message';
        }
        else {
            is $params{message}, sprintf("[%s] [%s] [%s] %s at %s line %s\n",
                @params{qw/localtime pkg time sql file line/}
            ), 'message';
        }
    };
}

my $dbh = t::Util->new_dbh;

subtest fh => sub {
    my $dbh = t::Util->new_dbh;
    my ($fh, $fname) = tempfile UNLINK => 1;
    $fh->autoflush(1);
    local $DBIx::QueryLog::OUTPUT = $fh;

    $dbh->do('SELECT * FROM sqlite_master');

    my $output = do {
        open my $rfh, '<', $fname or die $!;
        local $/; <$rfh>;
    };

    like $output, qr/SELECT \* FROM sqlite_master/, 'output ok';
};

test_params cb => sub {
    $dbh->do('SELECT * FROM sqlite_master');
};

test_params 'cb (execute)' => sub {
    $dbh->do('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
}, ['foo'];

test_params 'cb with skip_bind (execute)' => sub {
    DBIx::QueryLog->skip_bind(1);
    $dbh->do('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
    DBIx::QueryLog->skip_bind(0);
}, ['foo'], skip_bind => 1;

test_params 'cb (execute / bind)' => sub {
    my $sth = $dbh->prepare('SELECT * FROM sqlite_master WHERE name = ?');
    $sth->bind_param(1, 'foo');
    $sth->execute();
}, ['foo'];

test_params 'cb with skip_bind (execute / bind)' => sub {
    DBIx::QueryLog->skip_bind(1);
    my $sth = $dbh->prepare('SELECT * FROM sqlite_master WHERE name = ?');
    $sth->bind_param(1, 'foo');
    $sth->execute();
    DBIx::QueryLog->skip_bind(0);
}, ['foo'], skip_bind => 1;

test_params 'cb (selectrow_array)' => sub {
    $dbh->selectrow_array('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
}, ['foo'];

test_params 'cb with skip_bind (selectrow_array)' => sub {
    DBIx::QueryLog->skip_bind(1);
    $dbh->selectrow_array('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
    DBIx::QueryLog->skip_bind(0);
}, ['foo'], skip_bind => 1;

if (eval { require Test::mysqld; 1 }) {
    DBIx::QueryLog->end;
    if (my $mysqld = t::Util->setup_mysqld) {
        DBIx::QueryLog->begin;
        my $dbh = DBI->connect(
            $mysqld->dsn(dbname => 'mysql'), '', '',
            {
                AutoCommit => 1,
                RaiseError => 1,
            },
        ) or die $DBI::errstr;

        test_params 'do (mysqld)' => sub {
            $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'foo');
        }, ['foo'];

        test_params 'do with skip_bind (mysqld)' => sub {
            DBIx::QueryLog->skip_bind(1);
            $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'foo');
            DBIx::QueryLog->skip_bind(0);
        }, ['foo'], skip_bind => 1;
    }
}

done_testing;
