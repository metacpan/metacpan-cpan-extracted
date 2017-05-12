use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use Test::mysqld;
use t::Util;
use DBIx::Tracer ();
use DBI;

my $mysqld = t::Util->setup_mysqld
    or plan skip_all => $Test::mysqld::errstr || 'failed setup_mysqld';

my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'mysql'), '', '',
    {
        AutoCommit => 1,
        RaiseError => 1,
    },
) or die $DBI::errstr;

subtest 'do' => sub {
    my @res = capture {
        $dbh->do('SELECT * FROM user WHERE User = ?', undef, 'root');
    };

    is 0+@res, 1;
    is $res[0]->{sql}, 'SELECT * FROM user WHERE User = ?';
    is_deeply $res[0]->{bind_params}, ['root'];
};

subtest 'bind_param' => sub {
    my @res = capture {
        my $sth = $dbh->prepare('SELECT * FROM user WHERE User = ?');
        $sth->bind_param(1, 'root');
        $sth->execute;
    };

    is 0+@res, 1;
    is $res[0]->{sql}, 'SELECT * FROM user WHERE User = ?';
    is_deeply $res[0]->{bind_params}, ['root'];
};

done_testing;
