#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::PostgreSQL;
use AnyEvent;
use File::Basename;
use File::Spec;
use Promises backend => ['AnyEvent'], qw(deferred);
use Try::Tiny;

use AnyEvent::PgRecvlogical;

sub ae_sleep {
    my $t = shift || 0;
    my $cv = AE::cv;
    $cv->begin; my $wt = AE::timer $t, 0, sub { $cv->end };
    $cv->recv;
}

my $t_dir = File::Spec->rel2abs(dirname(__FILE__));
my $pg_hba_conf = File::Spec->join($t_dir, 'pg_hba.conf');

my $pg = eval {
    Test::PostgreSQL->new(extra_postmaster_args =>
          "-c hba_file='$pg_hba_conf' -c wal_level=logical -c max_wal_senders=1 -c max_replication_slots=1");
}
  or plan skip_all => "cannot create test postgres database: $Test::PostgreSQL::errstr";

my @expected = (
    'BEGIN',
    "table public.test_tbl: INSERT: id[integer]:1 payload[text]:'qwerty'",
    'COMMIT',
    'BEGIN',
    "table public.test_tbl: INSERT: id[integer]:2 payload[text]:'asdfgh'",
    'COMMIT',
);

my $control = DBI->connect($pg->dsn, 'postgres');
$control->do('create table test_tbl (id int primary key, payload text)');

my $end_cv = AE::cv;

my $recv = new_ok(
    'AnyEvent::PgRecvlogical' => [
        dbname         => 'test',
        host           => '127.0.0.1',
        port           => $pg->port,
        username       => 'postgres',
        slot           => 'test',
        options        => { 'skip-empty-xacts' => 1, 'include-xids' => 0 },
        do_create_slot => 1,
        slot_exists_ok => 1,
        heartbeat      => 1,
        reconnect_delay => 1,
        on_message     => sub { 
            is $_[0], shift @expected, $_[0];
            $end_cv->send(1) unless @expected;
        },
        on_error => sub { fail $_[0]; $end_cv->croak(@_) },
    ],
    'pg_recvlogical'
);

ok $recv->dbh, 'connected';

$recv->start->done( sub { pass 'replication started' }, sub { fail 'replication started'; diag @_ });

ae_sleep(2);

$control->do('insert into test_tbl (id, payload) values (?, ?)', undef, 1, 'qwerty');

ae_sleep(2);

$control->do('select pg_terminate_backend(?)', undef, $recv->dbh->{pg_pid});

ae_sleep(2);

$control->do('insert into test_tbl (id, payload) values (?, ?)', undef, 2, 'asdfgh');

# let some heartbeats go by
ae_sleep(3);

$recv->pause;

ok $recv->is_paused, 'sucessfully paused';

$control->do('insert into test_tbl (id, payload) values (?, ?)', undef, 3, 'frobnicate');

ae_sleep(1);

push @expected, (
    'BEGIN',
    "table public.test_tbl: INSERT: id[integer]:3 payload[text]:'frobnicate'",
    'COMMIT',
);

$recv->unpause;

ok !$recv->is_paused, 'sucessfully unpaused';

ae_sleep(2);

ok $end_cv->recv, 'got all messages';
$recv->stop;

$end_cv = AE::cv;

$recv = new_ok(
    'AnyEvent::PgRecvlogical' => [
        dbname          => 'no_exist',
        host            => '127.0.0.1',
        port            => $pg->port,
        username        => 'postgres',
        slot            => 'test',
        options         => { 'skip-empty-xacts' => 1, 'include-xids' => 0 },
        do_create_slot  => 1,
        slot_exists_ok  => 1,
        heartbeat       => 1,
        reconnect_delay => 1,
        on_message      => sub {
            return;
        },
        on_error => sub {
            $end_cv->croak(@_);
        },
    ],
    'pg_recvlogical'
);

my $error = '';
try {
    $recv->start;

    ae_sleep(1);
    $end_cv->send;
    ae_sleep(1);

    $end_cv->recv;
} catch {
    $error = $_;
};

ok !!$error, 'start died on connect error';

done_testing;
