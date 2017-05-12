use strict;
use warnings;
use DBIx::Handler;
use Test::More;
use Test::Requires 'DBD::SQLite';

my $handler = DBIx::Handler->new('dbi:SQLite:./txn_test.db','','');
isa_ok $handler, 'DBIx::Handler';
isa_ok $handler->dbh, 'DBI::db';

$handler->dbh->do(q{
    create table run_test (
        id int(10) NOT NULL,
        name varchar(10) NOT NULL,
        PRIMARY KEY (name)
    );
});

sub set_data {
    my $dbh = shift;
    $dbh ||= $handler->dbh;
    $dbh->do(q{insert into run_test (id, name) values (1, 'nekokak')});
}

sub reset_data {
    my $dbh = shift;
    $dbh ||= $handler->dbh;
    $dbh->do('delete from run_test');
}

subtest 'run scalar' => sub {
    my $row = $handler->run(sub {
        my $dbh = shift;
        set_data($dbh);
        return $dbh->selectrow_arrayref('select id, name from run_test');
    });
    is_deeply $row, [1, 'nekokak'];
    reset_data();
};

subtest 'run wantarray' => sub {
    my ($id, $name) = $handler->run(sub {
        my $dbh = shift;
        set_data($dbh);
        return $dbh->selectrow_array('select id, name from run_test');
    });
    is_deeply [$id, $name], [1, 'nekokak'];
    reset_data();
};

unlink './txn_test.db';

done_testing;
