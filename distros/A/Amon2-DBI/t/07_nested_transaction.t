use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::DBI;
use Test::Requires 'DBD::SQLite';

my $COUNTER = 0;
{
    no warnings 'once';
    my $orig = Amon2::DBI::db->can('DESTROY') or die;
    *Amon2::DBI::db::DESTROY = sub {
        $COUNTER++;
        $orig->(@_);
    };
}

subtest 'x' => sub {
    my $dbh = Amon2::DBI->connect('dbi:SQLite::memory:', '', '', {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
    });
    $dbh->do(q{CREATE TABLE foo (id INT UNSGINED)});
    $dbh->do(q{INSERT INTO foo (id) VALUES (1)});
    {
        my $txn1 = $dbh->txn_scope();
        $dbh->do(q{INSERT INTO foo (id) VALUES (2)});
        {
            my $txn2 = $dbh->txn_scope();
            $dbh->do(q{INSERT INTO foo (id) VALUES (3)});
            $txn2->rollback;
        }
        eval { $txn1->commit };
        ok $@;
        like $@, qr/tried to commit but already rollbacked in nested transaction/;
    }
    my $cnt = $dbh->selectrow_array(q{SELECT COUNT(*) FROM foo});
    is($cnt, 1);
};

subtest 'y' => sub {
    my $dbh = Amon2::DBI->connect('dbi:SQLite::memory:', '', '', {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
    });
    $dbh->do(q{CREATE TABLE foo (id INT UNSGINED)});
    $dbh->do(q{INSERT INTO foo (id) VALUES (1)});
    {
        my $txn1 = $dbh->txn_scope();
        $dbh->do(q{INSERT INTO foo (id) VALUES (2)});
        {
            my $txn2 = $dbh->txn_scope();
            $dbh->do(q{INSERT INTO foo (id) VALUES (3)});
            $txn2->commit;
        }
        $txn1->rollback;
    }
    my $cnt = $dbh->selectrow_array(q{SELECT COUNT(*) FROM foo});
    is($cnt, 1);
};

cmp_ok($COUNTER, '>=', 2);

done_testing;

