use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use Test::mysqld;
use t::Util;
use DBIx::Tracer ();
use DBI qw(:sql_types);

my $mysqld = t::Util->setup_mysqld
    or plan skip_all => $Test::mysqld::errstr || 'failed setup_mysqld';

my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'mysql'), '', '',
    {
        AutoCommit => 1,
        RaiseError => 1,
    },
) or die $DBI::errstr;

my @res = capture {
    my $sth = $dbh->prepare('SELECT * FROM user WHERE User = ? OR User = ?');
    $sth->bind_param(1, 1, { TYPE => SQL_INTEGER });
    $sth->bind_param(2, 'root', SQL_CHAR);
    $sth->execute;
    $sth->execute(3, 'dummy');
};

is 0+@res, 2;
is $res[0]->{sql}, 'SELECT * FROM user WHERE User = ? OR User = ?';
is_deeply $res[0]->{bind_params}, [1, 'root'];
is $res[1]->{sql}, 'SELECT * FROM user WHERE User = ? OR User = ?';
is_deeply $res[1]->{bind_params}, [3, 'dummy'];

done_testing;
