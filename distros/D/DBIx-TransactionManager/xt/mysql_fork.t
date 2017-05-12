use strict;
use warnings;
use utf8;
use Test::More;
use DBIx::TransactionManager;

BEGIN {
    eval "use Test::mysqld";
    plan skip_all => 'needs Test::mysqld for testing' if $@;
}

my $mysqld = Test::mysqld->new(
    my_cnf => {
      'skip-networking' => '', # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

subtest 'do scope commit' => sub {
    my $dbh = DBI->connect($mysqld->dsn(dbname => 'test'),'','',{
        AutoInactiveDestroy => 1,
    });
    $dbh->do('create table foo (id INTEGER PRIMARY KEY, var text) ENGINE=InnoDB');

    my $tm = DBIx::TransactionManager->new($dbh);

    my $txn = $tm->txn_scope;
    $dbh->do("insert into foo (id, var) values (1,'baz')");

    if ( fork ) {
        wait;
    }
    else {
        sleep 2;
        exit(0);
    }
    $dbh->do("update foo set var='woody' where id=1");
    $txn->commit;

    my $row = $dbh->selectrow_hashref('select * from foo');
    is $row->{id},  1;
    is $row->{var}, 'woody';
};

done_testing;

