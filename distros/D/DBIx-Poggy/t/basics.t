use strict; use warnings;

use Test::More !$ENV{POGGY_TEST_DSN}? (skip_all => 'no POGGY_TEST_DSN set') : ();
use_ok('AnyEvent');
use Promises qw(collect);

use_ok 'DBIx::Poggy';
my $pool = DBIx::Poggy->new;
$pool->connect($ENV{POGGY_TEST_DSN}, 'postgres');

my $dbh = $pool->take(auto => 0);
ok $dbh, 'got dbh';

my $cv = AnyEvent->condvar;
$dbh->do(
    'CREATE TABLE IF NOT EXISTS poggy_users (email varchar(255) primary key, password varchar(64))'
)->done(
    sub { ok $_[0], "created table"; $cv->send },
    sub { fail "error is not expected, but we got: ". $_[0]->{errstr}; $cv->send }
);
$cv->recv;

my $cv = AnyEvent->condvar;
$dbh->do(
    'DELETE FROM poggy_users'
)->done(
    sub { ok $_[0], "deleted poggy_users"; $cv->send },
    sub { fail "error is not expected, but we got: ". $_[0]->{errstr}; $cv->send }
);
$cv->recv;

$cv = AnyEvent->condvar;
$dbh->selectrow_array(
    'INSERT INTO poggy_users(email, password) VALUES (?,?) RETURNING email',
    undef, 'xxx@email.com', '1'
)->done(
    sub { is $_[0], 'xxx@email.com'; $cv->send },
    sub { fail "error is not expected, but we got: ". $_[0]->{errstr}; $cv->send }
);
$cv->recv;

$cv = AnyEvent->condvar;
$dbh->selectrow_array(
    'INSERT INTO poggy_users(email, password) VALUES (?,?) RETURNING email',
    undef, 'xxx@email.com', '1'
)->done(
    sub { fail 'success is not expected'; $cv->send },
    sub {
        pass 'error is expected';
        is $_[0]->{state}, 23505;
        $cv->send;
    },
);
$cv->recv;

$cv = AnyEvent->condvar;
$dbh->selectrow_array(
    'INSERT INTO poggy_users(email, password) VALUES (?,?) RETURNING email',
    undef, 'yyy@email.com', '1'
)->done(
    sub { is $_[0], 'yyy@email.com'; $cv->send },
    sub { fail "error is not expected"; $cv->send }
);
$cv->recv;

$cv = AnyEvent->condvar;
my $q1 = $dbh->selectrow_array(
    'INSERT INTO poggy_users(email, password) VALUES (?,?) RETURNING email',
    undef, 'zzz@email.com', '1'
);
my $q2 = $dbh->selectrow_array(
    'INSERT INTO poggy_users(email, password) VALUES (?,?) RETURNING email',
    undef, 'foo@email.com', '1'
);
collect($q1, $q2)->then(
    sub {is_deeply \@_, [['zzz@email.com'],['foo@email.com']]; $cv->send},
    sub { fail "error is not expected"; $cv->send }
);
$cv->recv;

done_testing;
