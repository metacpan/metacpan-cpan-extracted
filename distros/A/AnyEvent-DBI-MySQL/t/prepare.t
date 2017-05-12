#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Database;
use AnyEvent;

use AnyEvent::DBI::MySQL;


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';

my $dbh = AnyEvent::DBI::MySQL->connect($h->connection_info);
my ($sth, $sth1, $sth2);
my $res;

ok $dbh->do('CREATE TABLE IF NOT EXISTS Async (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, s VARCHAR(255) NOT NULL)');
ok $dbh->do('TRUNCATE TABLE Async');

$sth  = $dbh->prepare('INSERT INTO Async (s) VALUES (?), (?)', {async=>0});
$sth1 = $dbh->prepare('INSERT INTO Async (s) VALUES (?)');
$sth2 = $dbh->prepare('SELECT * FROM Async WHERE id > ?');

push my @tests,
sub {
    $sth1->execute('one', sub {
        ok shift, 'async insert1';
        $sth1->execute('two', sub {
            ok shift, 'async insert2';
            $sth1->execute('three', sub {
                ok shift, 'async insert3';
                NEXT();
            });
        });
    });
},
sub {
    is $sth->execute('four', 'five'), 2, 'sth sync';
    NEXT();
},
sub {
    $sth2->execute(2, sub {
        my ($res, $sth) = @_;
        is $res, 3, 'async select';
        is_deeply $sth->fetchall_arrayref, [[3,'three'],[4,'four'],[5,'five']], 'fetchall';
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
