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
my $cv;

$dbh->do('CREATE TABLE IF NOT EXISTS Async
    (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)', $cv=AE::cv);
is($cv->recv, '0E0', 'CREATE TABLE');

$dbh->do('TRUNCATE TABLE Async', $cv=AE::cv);
is($cv->recv, '0E0', 'TRUNCATE TABLE');

$dbh->do('INSERT INTO Async SET s="first"', $cv=AE::cv);
is($cv->recv, 1, 'INSERT');
is($dbh->{mysql_insertid}, 1, '… id=1');

$dbh->do('INSERT INTO Async SET s="secnd"', $cv=AE::cv);
is($cv->recv, 1, 'INSERT');
is($dbh->{mysql_insertid}, 2, '… id=2');
is($dbh->errstr, undef, '… no error');

$dbh->do('INSERT INTO Async SET id=2, s="second"', $cv=AE::cv);
is($cv->recv, undef, 'INSERT failed');
like($dbh->errstr, qr/Duplicate/, '… got error');

$dbh->do('UPDATE Async SET s="second" WHERE s="secnd"', $cv=AE::cv);
is($cv->recv, 1, 'UPDATE');
is($dbh->errstr, undef, '… no error');

$dbh->do('INSERT INTO Async SET id=2, s="second"', $cv=AE::cv);
is($cv->recv, undef, 'INSERT failed');
like($dbh->errstr, qr/Duplicate/, '… got error');

$dbh->do('UPDATE Async SET s="second" WHERE s="secnd"', $cv=AE::cv);
is($cv->recv, '0E0', 'UPDATE nothing');
is($dbh->errstr, undef, '… no error');

$dbh->do('REPLACE INTO Async SET id=2, s="two"', $cv=AE::cv);
is($cv->recv, 2, 'REPLACE mod');

$dbh->do('REPLACE INTO Async SET id=3, s="three"', $cv=AE::cv);
is($cv->recv, 1, 'REPLACE add');

$dbh->do('DELETE FROM Async WHERE id>3', $cv=AE::cv);
is($cv->recv, '0E0', 'DELETE none');

$dbh->do('DELETE FROM Async WHERE id>?', undef, 1, $cv=AE::cv);
is($cv->recv, 2, 'DELETE');

$dbh->do('INSERT INTO Async (s) VALUES ("two"),("three"),("four"),("five")', $cv=AE::cv);
is($cv->recv, 4, 'INSERT batch');
is($dbh->{mysql_insertid}, 4, '… id=4');

($sth = $dbh->prepare('SELECT * FROM Async WHERE id>? ORDER BY id'))->execute(4, $cv=AE::cv);
is($cv->recv, 3, 'execute');
is_deeply($sth->fetchall_arrayref({}), [{id=>5,s=>'three'},{id=>6,s=>'four'},{id=>7,s=>'five'}], 'SELECT fetchall_arrayref');

($sth = $dbh->prepare('SELECT * FROM Async WHERE id=?'))->execute(5, $cv=AE::cv);
is($cv->recv, 1, 'execute');
is_deeply($sth->fetchrow_hashref(), {id=>5,s=>'three'}, 'SELECT fetchrow_hashref');

$dbh->selectall_arrayref('SELECT * FROM Async WHERE id<?', undef, 5, $cv=AE::cv);
is_deeply($cv->recv, [[1, 'first'],[4, 'two']], 'selectall_arrayref');

$dbh->selectall_hashref('SELECT * FROM Async WHERE id<?', 'id', undef, 5, $cv=AE::cv);
is_deeply($cv->recv, {1=>{id=>1,s=>'first'},4=>{id=>4,s=>'two'}}, 'selectall_hashref');

$dbh->selectcol_arrayref('SELECT s FROM Async WHERE id<?', undef, 5, $cv=AE::cv);
is_deeply($cv->recv, ['first','two'], 'selectcol_arrayref');

$dbh->selectrow_array('SELECT * FROM Async WHERE id=?', undef, 1, $cv=AE::cv);
my @res = $cv->recv;
is_deeply(\@res, [1, 'first'], 'selectrow_array');

$dbh->selectrow_arrayref('SELECT * FROM Async WHERE id=?', undef, 1, $cv=AE::cv);
is_deeply($cv->recv, [1, 'first'], 'selectrow_arrayref');

$dbh->selectrow_hashref('SELECT * FROM Async WHERE id=?', undef, 1, $cv=AE::cv);
is_deeply($cv->recv, {id=>1,s=>'first'}, 'selectrow_hashref');

($sth1 = $dbh->prepare_cached('SELECT * FROM Async WHERE id=?'))->execute(5, $cv=AE::cv);
is($cv->recv, 1, 'execute');
is_deeply($sth1->fetchrow_hashref(), {id=>5,s=>'three'}, 'prepare_cached');
is_deeply($sth1->fetchrow_hashref(), undef, '… no more records');

($sth2 = $dbh->prepare_cached('SELECT * FROM Async WHERE id=?'))->execute(4, $cv=AE::cv);
is($cv->recv, 1, 'execute');
is_deeply($sth2->fetchrow_hashref(), {id=>4,s=>'two'}, 'prepare_cached');
is_deeply($sth2->fetchrow_hashref(), undef, '… no more records');
is($sth1, $sth2, 'sth really was cached');

$sth = $dbh->prepare('SELECT * FROM Async WHERE id=?');
$sth->bind_param(1, 5);
$sth->execute($cv=AE::cv);
is($cv->recv, 1, 'execute');
is_deeply($sth->fetchrow_hashref(), {id=>5,s=>'three'}, 'bind_param');

$sth = $dbh->prepare('INSERT INTO Async (id,s) VALUES (?,?)', {async=>0});
my $tuples = $sth->execute_array(
    { ArrayTupleStatus => \my @tuple_status },
    [ 10, 20 ],
    [ 'ten', 'twenty' ],
);
is($tuples, 2, '[SYNC] execute_array');
is_deeply(\@tuple_status, [1,1], '… ArrayTupleStatus');

$dbh->do('DROP TABLE Async', $cv=AE::cv);
is($cv->recv, '0E0', 'DROP TABLE');


done_testing();
