#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Database;
use AnyEvent;

use AnyEvent::DBI::MySQL;


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';

my $dbh = AnyEvent::DBI::MySQL->connect($h->connection_info, {PrintError=>0});
my ($sth, $sth1, $sth2);
my $res;

push my @tests,
sub {
    $dbh->do('CREATE TABLE IF NOT EXISTS Async
        (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)', sub {
    $res = shift;
    is($res, '0E0', 'CREATE TABLE');
    NEXT();
    });
},
sub {
    $dbh->do('TRUNCATE TABLE Async', sub {
    $res = shift;
    is($res, '0E0', 'TRUNCATE TABLE');
    NEXT();
    });
},
sub {
    $dbh->do('INSERT INTO Async SET s="first"', sub {
    $res = shift;
    is($res, 1, 'INSERT');
    is($dbh->{mysql_insertid}, 1, '… id=1');
    NEXT();
    });
},
sub {
    $dbh->do('INSERT INTO Async SET s="secnd"', sub {
    $res = shift;
    is($res, 1, 'INSERT');
    is($dbh->{mysql_insertid}, 2, '… id=2');
    is($dbh->errstr, undef, '… no error');
    NEXT();
    });
},
sub {
    $dbh->do('INSERT INTO Async SET id=2, s="second"', sub {
    $res = shift;
    is($res, undef, 'INSERT failed');
    like($dbh->errstr, qr/Duplicate/, '… got error');
    NEXT();
    });
},
sub {
    $dbh->do('UPDATE Async SET s="second" WHERE s="secnd"', sub {
    $res = shift;
    is($res, 1, 'UPDATE');
    is($dbh->errstr, undef, '… no error');
    NEXT();
    });
},
sub {
    $dbh->do('INSERT INTO Async SET id=2, s="second"', sub {
    $res = shift;
    is($res, undef, 'INSERT failed');
    like($dbh->errstr, qr/Duplicate/, '… got error');
    NEXT();
    });
},
sub {
    $dbh->do('UPDATE Async SET s="second" WHERE s="secnd"', sub {
    $res = shift;
    is($res, '0E0', 'UPDATE nothing');
    is($dbh->errstr, undef, '… no error');
    NEXT();
    });
},
sub {
    $dbh->do('REPLACE INTO Async SET id=2, s="two"', sub {
    $res = shift;
    is($res, 2, 'REPLACE mod');
    NEXT();
    });
},
sub {
    $dbh->do('REPLACE INTO Async SET id=3, s="three"', sub {
    $res = shift;
    is($res, 1, 'REPLACE add');
    NEXT();
    });
},
sub {
    $dbh->do('DELETE FROM Async WHERE id>3', sub {
    $res = shift;
    is($res, '0E0', 'DELETE none');
    NEXT();
    });
},
sub {
    $dbh->do('DELETE FROM Async WHERE id>?', undef, 1, sub {
    $res = shift;
    is($res, 2, 'DELETE');
    NEXT();
    });
},
sub {
    $dbh->do('INSERT INTO Async (s) VALUES ("two"),("three"),("four"),("five")', sub {
    $res = shift;
    is($res, 4, 'INSERT batch');
    is($dbh->{mysql_insertid}, 4, '… id=4');
    NEXT();
    });
},
sub {
    ($sth = $dbh->prepare('SELECT * FROM Async WHERE id>? ORDER BY id'))->execute(4, sub {
    $res = shift;
    is($res, 3, 'execute');
    is_deeply($sth->fetchall_arrayref({}), [{id=>5,s=>'three'},{id=>6,s=>'four'},{id=>7,s=>'five'}], 'SELECT fetchall_arrayref');
    NEXT();
    });
},
sub {
    ($sth = $dbh->prepare('SELECT * FROM Async WHERE id=?'))->execute(5, sub {
    $res = shift;
    is($res, 1, 'execute');
    is_deeply($sth->fetchrow_hashref(), {id=>5,s=>'three'}, 'SELECT fetchrow_hashref');
    NEXT();
    });
},
sub {
    $dbh->selectall_arrayref('SELECT * FROM Async WHERE id<?', undef, 5, sub {
    $res = shift;
    is_deeply($res, [[1, 'first'],[4, 'two']], 'selectall_arrayref');
    NEXT();
    });
},
sub {
    $dbh->selectall_hashref('SELECT * FROM Async WHERE id<?', 'id', undef, 5, sub {
    $res = shift;
    is_deeply($res, {1=>{id=>1,s=>'first'},4=>{id=>4,s=>'two'}}, 'selectall_hashref');
    NEXT();
    });
},
sub {
    $dbh->selectcol_arrayref('SELECT s FROM Async WHERE id<?', undef, 5, sub {
    $res = shift;
    is_deeply($res, ['first','two'], 'selectcol_arrayref');
    NEXT();
    });
},
sub {
    $dbh->selectrow_array('SELECT * FROM Async WHERE id=?', undef, 1, sub {
    my @res = @_;
    is_deeply(\@res, [1, 'first'], 'selectrow_array');
    NEXT();
    });
},
sub {
    $dbh->selectrow_arrayref('SELECT * FROM Async WHERE id=?', undef, 1, sub {
    $res = shift;
    is_deeply($res, [1, 'first'], 'selectrow_arrayref');
    NEXT();
    });
},
sub {
    $dbh->selectrow_hashref('SELECT * FROM Async WHERE id=?', undef, 1, sub {
    $res = shift;
    is_deeply($res, {id=>1,s=>'first'}, 'selectrow_hashref');
    NEXT();
    });
},
sub {
    ($sth1 = $dbh->prepare_cached('SELECT * FROM Async WHERE id=?'))->execute(5, sub {
    $res = shift;
    is($res, 1, 'execute');
    is_deeply($sth1->fetchrow_hashref(), {id=>5,s=>'three'}, 'prepare_cached');
    is_deeply($sth1->fetchrow_hashref(), undef, '… no more records');
    NEXT();
    });
},
sub {
    ($sth2 = $dbh->prepare_cached('SELECT * FROM Async WHERE id=?'))->execute(4, sub {
    $res = shift;
    is($res, 1, 'execute');
    is_deeply($sth2->fetchrow_hashref(), {id=>4,s=>'two'}, 'prepare_cached');
    is_deeply($sth2->fetchrow_hashref(), undef, '… no more records');
    is($sth1, $sth2, 'sth really was cached');
    NEXT();
    });
},
sub {
    $sth = $dbh->prepare('SELECT * FROM Async WHERE id=?');
    $sth->bind_param(1, 5);
    $sth->execute(sub {
    $res = shift;
    is($res, 1, 'execute');
    is_deeply($sth->fetchrow_hashref(), {id=>5,s=>'three'}, 'bind_param');
    NEXT();
    });
},
sub {
    $sth = $dbh->prepare('INSERT INTO Async (id,s) VALUES (?,?)', {async=>0});
    my $tuples = $sth->execute_array(
        { ArrayTupleStatus => \my @tuple_status },
        [ 10, 20 ],
        [ 'ten', 'twenty' ],
    );
    is($tuples, 2, '[SYNC] execute_array');
    is_deeply(\@tuple_status, [1,1], '… ArrayTupleStatus');
    NEXT();
},
sub {
    $dbh->do('DROP TABLE Async', sub {
    $res = shift;
    is($res, '0E0', 'DROP TABLE');
    NEXT();
    });
},
sub {
    done_testing();
    exit;
};


sub NEXT {
    shift @tests;
    goto $tests[0];
}

$tests[0]->();

AnyEvent->condvar->recv;


done_testing();
