#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Database;

use AnyEvent::DBI::MySQL;


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';

my $dbh = AnyEvent::DBI::MySQL->connect($h->connection_info, {RaiseError=>1,PrintError=>0});
my ($sth, $sth1, $sth2);
my $res;

push my @tests,
sub {
    $res = $dbh->do('CREATE TABLE IF NOT EXISTS Async
        (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)');
    is($res, '0E0', 'CREATE TABLE');
},
sub {
    $res = $dbh->do('TRUNCATE TABLE Async');
    is($res, '0E0', 'TRUNCATE TABLE');
},
sub {
    $res = $dbh->do('INSERT INTO Async SET s="first"');
    is($res, 1, 'INSERT');
    is($dbh->{mysql_insertid}, 1, '… id=1');
},
sub {
    $res = $dbh->do('INSERT INTO Async SET s="secnd"');
    is($res, 1, 'INSERT');
    is($dbh->{mysql_insertid}, 2, '… id=2');
    is($dbh->errstr, undef, '… no error');
},
sub {
    local $dbh->{RaiseError} = 0;
    $res = $dbh->do('INSERT INTO Async SET id=2, s="second"');
    is($res, undef, 'INSERT failed');
    like($dbh->errstr, qr/Duplicate/, '… got error');
},
sub {
    $res = $dbh->do('UPDATE Async SET s="second" WHERE s="secnd"');
    is($res, 1, 'UPDATE');
    is($dbh->errstr, undef, '… no error');
},
sub {
    $res = eval { $dbh->do('INSERT INTO Async SET id=2, s="second"') };
    is($res, undef, 'INSERT failed');
    like($@, qr/Duplicate/, '… got eval error');
    like($dbh->errstr, qr/Duplicate/, '… got error');
},
sub {
    $res = $dbh->do('UPDATE Async SET s="second" WHERE s="secnd"');
    is($res, '0E0', 'UPDATE nothing');
    is($dbh->errstr, undef, '… no error');
},
sub {
    $res = $dbh->do('REPLACE INTO Async SET id=2, s="two"');
    is($res, 2, 'REPLACE mod');
},
sub {
    $res = $dbh->do('REPLACE INTO Async SET id=3, s="three"');
    is($res, 1, 'REPLACE add');
},
sub {
    $res = $dbh->do('DELETE FROM Async WHERE id>3');
    is($res, '0E0', 'DELETE none');
},
sub {
    $res = $dbh->do('DELETE FROM Async WHERE id>?', undef, 1);
    is($res, 2, 'DELETE');
},
sub {
    $res = $dbh->do('INSERT INTO Async (s) VALUES ("two"),("three"),("four"),("five")');
    is($res, 4, 'INSERT batch');
    is($dbh->{mysql_insertid}, 4, '… id=4');
},
sub {
    $res = ($sth = $dbh->prepare('SELECT * FROM Async WHERE id>? ORDER BY id', {async=>0}))->execute(4);
    is($res, 3, 'execute');
    is_deeply($sth->fetchall_arrayref({}), [{id=>5,s=>'three'},{id=>6,s=>'four'},{id=>7,s=>'five'}], 'SELECT fetchall_arrayref');
},
sub {
    ($sth = $dbh->prepare('SELECT * FROM Async WHERE id=?', {async=>0}))->execute(5, sub {
        $res = shift;
        is($res, 1, 'execute');
        is_deeply($sth->fetchrow_hashref(), {id=>5,s=>'three'}, 'SELECT fetchrow_hashref');
    });
},
sub {
    $res = $dbh->selectall_arrayref('SELECT * FROM Async WHERE id<?', undef, 5);
    is_deeply($res, [[1, 'first'],[4, 'two']], 'selectall_arrayref');
},
sub {
    $res = $dbh->selectall_hashref('SELECT * FROM Async WHERE id<?', 'id', undef, 5);
    is_deeply($res, {1=>{id=>1,s=>'first'},4=>{id=>4,s=>'two'}}, 'selectall_hashref');
},
sub {
    $res = $dbh->selectcol_arrayref('SELECT s FROM Async WHERE id<?', undef, 5);
    is_deeply($res, ['first','two'], 'selectcol_arrayref');
},
sub {
    my @res = $dbh->selectrow_array('SELECT * FROM Async WHERE id=?', undef, 1);
    is_deeply(\@res, [1, 'first'], 'selectrow_array');
},
sub {
    $res = $dbh->selectrow_arrayref('SELECT * FROM Async WHERE id=?', undef, 1);
    is_deeply($res, [1, 'first'], 'selectrow_arrayref');
},
sub {
    $res = $dbh->selectrow_hashref('SELECT * FROM Async WHERE id=?', undef, 1);
    is_deeply($res, {id=>1,s=>'first'}, 'selectrow_hashref');
},
sub {
    $res = ($sth1 = $dbh->prepare_cached('SELECT * FROM Async WHERE id=?', {async=>0}))->execute(5);
    is($res, 1, 'execute');
    is_deeply($sth1->fetchrow_hashref(), {id=>5,s=>'three'}, 'prepare_cached');
    is_deeply($sth1->fetchrow_hashref(), undef, '… no more records');
},
sub {
    $res = ($sth2 = $dbh->prepare_cached('SELECT * FROM Async WHERE id=?', {async=>0}))->execute(4);
    is($res, 1, 'execute');
    is_deeply($sth2->fetchrow_hashref(), {id=>4,s=>'two'}, 'prepare_cached');
    is_deeply($sth2->fetchrow_hashref(), undef, '… no more records');
    is($sth1, $sth2, 'sth really was cached');
},
sub {
    $sth = $dbh->prepare('SELECT * FROM Async WHERE id=?', {async=>0});
    $sth->bind_param(1, 5);
    $res = $sth->execute();
    is($res, 1, 'execute');
    is_deeply($sth->fetchrow_hashref(), {id=>5,s=>'three'}, 'bind_param');
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
},
sub {
    $res = $dbh->do('DROP TABLE Async');
    is($res, '0E0', 'DROP TABLE');
},
sub {
    done_testing();
    exit;
};


sub NEXT {
    shift @tests;
    goto $tests[0];
}

for (0 .. $#tests) {
    my $cb = $tests[$_];
    $tests[$_] = sub { &$cb; goto &NEXT; };
}
$tests[0]->();


done_testing();
