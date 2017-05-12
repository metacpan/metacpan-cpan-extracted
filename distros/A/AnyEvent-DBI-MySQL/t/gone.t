#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Database;
use AnyEvent;

use AnyEvent::DBI::MySQL;


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';

my %dbh;
$dbh{1} = AnyEvent::DBI::MySQL->connect($h->connection_info);
$dbh{2} = AnyEvent::DBI::MySQL->connect($h->connection_info);
$dbh{3} = AnyEvent::DBI::MySQL->connect($h->connection_info);
$dbh{4} = AnyEvent::DBI::MySQL->connect($h->connection_info);
$dbh{5} = AnyEvent::DBI::MySQL->connect($h->connection_info);
$dbh{6} = AnyEvent::DBI::MySQL->connect($h->connection_info);
my $res;
my @t;

push my @tests,
sub {
    my $dbh = $dbh{1};
    $dbh->do('SELECT SLEEP(0.1)', sub {
        ok 1, 'dbh1 callback fired';
        undef $t[1];
        NEXT();
    });
    $t[1] = AnyEvent->timer(after => 0.5, cb => sub {
        ok 0, 'dbh1 callback fired';
        delete $dbh{1};
        NEXT();
    });
},
sub {
    my $dbh = $dbh{2};
    $dbh->prepare('SELECT SLEEP(0.1)')->execute(sub {
        ok 1, 'dbh2 callback fired';
        undef $t[2];
        NEXT();
    });
    $t[2] = AnyEvent->timer(after => 0.5, cb => sub {
        ok 0, 'dbh2 callback fired';
        delete $dbh{2};
        NEXT();
    });
},
sub {
    my $dbh = $dbh{3};
    $dbh->selectall_arrayref('SELECT SLEEP(0.1)', sub {
        ok 1, 'dbh3 callback fired';
        undef $t[3];
        NEXT();
    });
    $t[3] = AnyEvent->timer(after => 0.5, cb => sub {
        ok 0, 'dbh3 callback fired';
        delete $dbh{3};
        NEXT();
    });
},
sub {
    my $dbh = delete $dbh{4};
    $dbh->do('SELECT SLEEP(0.1)', sub {
        ok 0, 'dbh4 callback ignored';
        undef $t[4];
        NEXT();
    });
    $t[4] = AnyEvent->timer(after => 0.5, cb => sub {
        ok 1, 'dbh4 callback ignored';
        NEXT();
    });
},
sub {
    my $dbh = delete $dbh{5};
    $dbh->prepare('SELECT SLEEP(0.1)')->execute(sub {
        ok 0, 'dbh5 callback ignored';
        undef $t[5];
        NEXT();
    });
    $t[5] = AnyEvent->timer(after => 0.5, cb => sub {
        ok 1, 'dbh5 callback ignored';
        NEXT();
    });
},
sub {
    my $dbh = delete $dbh{6};
    $dbh->selectall_arrayref('SELECT SLEEP(0.1)', sub {
        ok 0, 'dbh6 callback ignored';
        undef $t[6];
        NEXT();
    });
    $t[6] = AnyEvent->timer(after => 0.5, cb => sub {
        ok 1, 'dbh6 callback ignored';
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
