#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Database;
use AnyEvent;

use AnyEvent::DBI::MySQL;


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';

my $dbh = AnyEvent::DBI::MySQL->connect($h->connection_info, {PrintError=>0});


$dbh->do('CREATE TABLE IF NOT EXISTS Async
    (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)',
    {async=>0},
sub {
    my ($rv, $dbh) = @_;
    is($rv, '0E0', 'CREATE TABLE');
    is($dbh->errstr, undef, 'no error');
    $dbh->do('TRUNCATE TABLE Async');
});

$dbh->do('CREATE TABLE Async
    (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)',
    {async=>0},
sub {
    my ($rv, $dbh) = @_;
    is($rv, undef, 'CREATE TABLE failed');
    like($dbh->errstr, qr/already exists/, 'got error');
});

$dbh->prepare('INSERT INTO Async (id,s) VALUES (?,?),(?,?)',
    {async=>0})->execute(1,'one',2,'two',
sub {
    my ($rv, $sth) = @_;
    is($rv, 2, 'INSERT');
    is($sth->errstr, undef, 'no error');
});

$dbh->prepare('INSERT INTO Async SET id=?,s=?',
    {async=>0})->execute(1,'one',
sub {
    my ($rv, $sth) = @_;
    is($rv, undef, 'INSERT failed');
    like($sth->errstr, qr/Duplicate/, 'got error');
});

$dbh->prepare('INSERT INTO Async SET id=?,s=?',
    {async=>0})->execute(1,'one',2,'two',
sub {
    my ($rv, $sth) = @_;
    is($rv, undef, 'INSERT failed');
    like($sth->errstr, qr/bind variables/, 'got error from execute()');
});

$dbh->selectrow_array('SELECT * FROM Async',
    {async=>0},
sub {
    my (@res) = @_;
    is_deeply \@res, [1,'one'], 'selectrow_array';
    is($dbh->errstr, undef, 'no error');
});

$dbh->selectrow_array('SELECT bad1, bad2 FROM Async',
    {async=>0},
sub {
    my (@res) = @_;
    is_deeply \@res, [], 'selectrow_array failed';
    like($dbh->errstr, qr/Unknown column/, 'got error');
});

$dbh->selectrow_arrayref('SELECT * FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, [1,'one'], 'selectrow_arrayref';
    is($dbh->errstr, undef, 'no error');
});

$dbh->selectrow_arrayref('SELECT bad1, bad2 FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, undef, 'selectrow_arrayref failed';
    like($dbh->errstr, qr/Unknown column/, 'got error');
});

$dbh->selectrow_hashref('SELECT * FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, {id=>1,s=>'one'}, 'selectrow_hashref';
    is($dbh->errstr, undef, 'no error');
});

$dbh->selectrow_hashref('SELECT bad1, bad2 FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, undef, 'selectrow_hashref failed';
    like($dbh->errstr, qr/Unknown column/, 'got error');
});

$dbh->selectall_arrayref('SELECT * FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, [[1,'one'],[2,'two']], 'selectall_arrayref';
    is($dbh->errstr, undef, 'no error');
});

$dbh->selectall_arrayref('SELECT bad1, bad2 FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, undef, 'selectall_arrayref failed';
    like($dbh->errstr, qr/Unknown column/, 'got error');
});

$dbh->selectall_hashref('SELECT * FROM Async', 'id',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, {1=>{id=>1,s=>'one'},2=>{id=>2,s=>'two'}}, 'selectall_hashref';
    is($dbh->errstr, undef, 'no error');
});

$dbh->selectall_hashref('SELECT bad1, bad2 FROM Async', 'bad1',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, undef, 'selectall_hashref failed';
    like($dbh->errstr, qr/Unknown column/, 'got error');
});

$dbh->selectcol_arrayref('SELECT id FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, [1,2], 'selectcol_arrayref';
    is($dbh->errstr, undef, 'no error');
});

$dbh->selectcol_arrayref('SELECT bad1 FROM Async',
    {async=>0},
sub {
    my ($res) = @_;
    is_deeply $res, undef, 'selectcol_arrayref failed';
    like($dbh->errstr, qr/Unknown column/, 'got error');
});

$dbh->selectcol_arrayref('SELECT bad1 FROM Async',
    {async=>0}, 1,
sub {
    my ($res) = @_;
    is_deeply $res, undef, 'selectcol_arrayref failed';
    like($dbh->errstr, qr/bind variables/, 'got error from execute()');
});

push my @tests,
sub {
    $dbh->do('CREATE TABLE IF NOT EXISTS Async
        (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)',
    sub {
        my ($rv, $dbh) = @_;
        is($rv, '0E0', 'CREATE TABLE');
        is($dbh->errstr, undef, 'no error');
        $dbh->do('TRUNCATE TABLE Async');
        NEXT();
    });
},
sub {
    $dbh->do('CREATE TABLE Async
        (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)',
    sub {
        my ($rv, $dbh) = @_;
        is($rv, undef, 'CREATE TABLE failed');
        like($dbh->errstr, qr/already exists/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->prepare('INSERT INTO Async (id,s) VALUES (?,?),(?,?)',
        )->execute(1,'one',2,'two',
    sub {
        my ($rv, $sth) = @_;
        is($rv, 2, 'INSERT');
        is($sth->errstr, undef, 'no error');
        NEXT();
    });
},
sub {
    $dbh->prepare('INSERT INTO Async SET id=?,s=?',
        )->execute(1,'one',
    sub {
        my ($rv, $sth) = @_;
        is($rv, undef, 'INSERT failed');
        like($sth->errstr, qr/Duplicate/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->prepare('INSERT INTO Async SET id=?,s=?',
        )->execute(1,'one',2,'two',
    sub {
        my ($rv, $sth) = @_;
        is($rv, undef, 'INSERT failed');
        like($sth->errstr, qr/bind variables/, 'got error from execute()');
        NEXT();
    });
},
sub {
    $dbh->selectrow_array('SELECT * FROM Async',
    sub {
        my (@res) = @_;
        is_deeply \@res, [1,'one'], 'selectrow_array';
        is($dbh->errstr, undef, 'no error');
        NEXT();
    });
},
sub {
    $dbh->selectrow_array('SELECT bad1, bad2 FROM Async',
    sub {
        my (@res) = @_;
        is_deeply \@res, [], 'selectrow_array failed';
        like($dbh->errstr, qr/Unknown column/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->selectrow_arrayref('SELECT * FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, [1,'one'], 'selectrow_arrayref';
        is($dbh->errstr, undef, 'no error');
        NEXT();
    });
},
sub {
    $dbh->selectrow_arrayref('SELECT bad1, bad2 FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, undef, 'selectrow_arrayref failed';
        like($dbh->errstr, qr/Unknown column/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->selectrow_hashref('SELECT * FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, {id=>1,s=>'one'}, 'selectrow_hashref';
        is($dbh->errstr, undef, 'no error');
        NEXT();
    });
},
sub {
    $dbh->selectrow_hashref('SELECT bad1, bad2 FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, undef, 'selectrow_hashref failed';
        like($dbh->errstr, qr/Unknown column/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->selectall_arrayref('SELECT * FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, [[1,'one'],[2,'two']], 'selectall_arrayref';
        is($dbh->errstr, undef, 'no error');
        NEXT();
    });
},
sub {
    $dbh->selectall_arrayref('SELECT bad1, bad2 FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, undef, 'selectall_arrayref failed';
        like($dbh->errstr, qr/Unknown column/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->selectall_hashref('SELECT * FROM Async', 'id',
    sub {
        my ($res) = @_;
        is_deeply $res, {1=>{id=>1,s=>'one'},2=>{id=>2,s=>'two'}}, 'selectall_hashref';
        is($dbh->errstr, undef, 'no error');
        NEXT();
    });
},
sub {
    $dbh->selectall_hashref('SELECT bad1, bad2 FROM Async', 'bad1',
    sub {
        my ($res) = @_;
        is_deeply $res, undef, 'selectall_hashref failed';
        like($dbh->errstr, qr/Unknown column/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->selectcol_arrayref('SELECT id FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, [1,2], 'selectcol_arrayref';
        is($dbh->errstr, undef, 'no error');
        NEXT();
    });
},
sub {
    $dbh->selectcol_arrayref('SELECT bad1 FROM Async',
    sub {
        my ($res) = @_;
        is_deeply $res, undef, 'selectcol_arrayref failed';
        like($dbh->errstr, qr/Unknown column/, 'got error');
        NEXT();
    });
},
sub {
    $dbh->selectcol_arrayref('SELECT bad1 FROM Async', {}, 1,
    sub {
        my ($res) = @_;
        is_deeply $res, undef, 'selectcol_arrayref failed';
        like($dbh->errstr, qr/bind variables/, 'got error from execute()');
        NEXT();
    });
},
sub {
    $dbh->do('DROP TABLE Async');
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
