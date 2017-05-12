#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

# use Devel::FindRef;

$| = 1;
use Pg::PQ qw(:pgres);
use AnyEvent::Pg;
use AnyEvent::Pg::Pool;
use Test::More;

my ($ci, $tpg, $port);

if (defined $ENV{TEST_ANYEVENT_PG_CONNINFO}) {
    $ci = $ENV{TEST_ANYEVENT_PG_CONNINFO};
}
else {
    unless (eval { require Test::PostgreSQL; 1 }) {
        plan skip_all => "Unable to load Test::PostgreSQL: $@";
    }

    $tpg = eval { Test::PostgreSQL->new };
    unless ($tpg) {
        no warnings;
        plan skip_all => "Test::PostgreSQL failed to provide a database instance: $@";
    }


    $port = $tpg->port;
    $ci = { dbname => 'test',
            host   => '127.0.0.1',
            port   => $port,
            user   => 'postgres' };

    # use Data::Dumper;
    # diag(Data::Dumper->Dump( [$tpg, $ci], [qw(tpg *ci)]));
}

$port ||= 1234;

my @w;
my $queued = 0;

sub ok_query {
    my ($pg, @query) = @_;
    $queued++;
    my $ok;
    push @w, $pg->push_query(query => \@query,
                             on_error => sub {
                                 fail("query '@query' error: " . $_[1]->error);
                                 $queued--;
                             },
                             on_done  => sub {
                                 ok(defined $_[0]->last_query_start_time);
                                 # diag "last query start time: ", $_[0]->last_query_start_time, ", now: ", AE::now;

                                 ok($ok, "query '@query'");
                                 $queued--;
                             },
                             on_result => sub {
                                 my $status = $_[1]->status;
                                 $ok = 1 if $status == PGRES_TUPLES_OK or $status == PGRES_COMMAND_OK;
                             } );
}

sub fail_query {
    my ($pg, @query) = @_;
    $queued++;
    my $ok;
    push @w, $pg->push_query(query => \@query,
                             on_error => sub {
                                 fail("query '@query' error: " . $_[1]->error);
                                 $queued--;
                             },
                             on_done  => sub {
                                 ok(!$ok, "query '@query' should fail");
                                 $queued--;
                             },
                             on_result => sub {
                                 my $status = $_[1]->status;
                                 $ok = 1 if $status == PGRES_TUPLES_OK or $status == PGRES_COMMAND_OK;
                             } );
}


sub ok_query_prepare {
    my ($pg, $name, $query) = @_;
    $queued++;
    my $ok;
    push @w, $pg->push_prepare(name => $name, query => $query,
                               on_error => sub {
                                   fail("prepare query $name => '$query' error: " . $_[1]->error);
                                   $queued--;
                               },
                               on_done  => sub {
                                   ok($ok, "prepare query $name => '$query' passed");
                                   $queued--;
                               },
                               on_result => sub {
                                   my $status = $_[1]->status;
                                   $ok = 1 if $status == PGRES_COMMAND_OK;
                               } );
}

sub ok_query_prepared {
    my ($pg, $name, @args) = @_;
    $queued++;
    my $ok;
    push @w, $pg->push_query_prepared(name => $name, args => \@args,
                                      on_error => sub {
                                          fail("prepared query $name => '@args' error: " . $_[1]->error);
                                          $queued--;
                                      },
                                      on_done  => sub {
                                          ok($ok, "prepared query $name => '@args' passed");
                                          $queued--;
                                      },
                                      on_result => sub {
                                          my $status = $_[1]->status;
                                          $ok = 1 if $status == PGRES_TUPLES_OK or $status == PGRES_COMMAND_OK;
                                      } );

}

###########################################################################################33
#
# Tests go here:
#
#


plan tests => 28;
diag "conninfo: " . Pg::PQ::Conn::_make_conninfo($ci);

my $timer;
my $cv = AnyEvent->condvar;
my $pg = AnyEvent::Pg->new($ci,
                           on_connect       => sub { pass("connected") },
                           on_connect_error => sub { fail("connect error") },
                           on_empty_queue   => sub {
                               ok ($queued == 0, "queue is empty");
                               undef $timer;
                               $cv->send;
                           } );

fail_query($pg, 'drop table foo');
fail_query($pg, 'drop table bar');
ok_query($pg, 'create table foo (id int, name varchar(20))');
ok_query_prepare($pg, populate_foo => 'insert into foo (id, name) values ($1, $2)');

my %data = ( hello => 10, hola => 45, cheers => 1);
ok_query($pg, 'insert into foo (id, name) values ($1, $2)', $data{$_}, $_)
    for keys %data;

ok_query_prepare($pg, foo_bigger => 'select * from foo where id > $1 order by id desc');

my %data1 = ( bye => 12, goodbye => 13, adios => 111, 'hasta la vista' => 41);
ok_query_prepared($pg, populate_foo => $data1{$_}, $_)
    for keys %data1;

ok_query($pg, 'select * from foo');
ok_query_prepared($pg, 'foo_bigger', 12);
ok_query($pg, 'select * from foo where id < 12 order by name; select * from foo where id > 12 order by name');

$timer = AE::timer 120, 0, sub {
    fail("timeout");
    $cv->send;
};

$cv->recv;
pass("after recv");

$cv = AnyEvent->condvar;
$pg = AnyEvent::Pg->new($ci,
                        on_empty_queue   => sub {
                            ok ($queued == 0, "queue is empty");
                            undef $timer;
                            $cv->send;
                        } );


$timer = AE::timer 120, 0, sub {
    fail("timeout");
    $cv->send;
};

$cv->recv;
pass("after recv 2");

undef $pg;
undef @w;

##############################
#
# Pool tests:
#

$cv = AnyEvent->condvar;

my $global_timeout = 10;
my $timeout        =  1;
my $delay          =  2;
my $max_ok = $global_timeout + $timeout * 2 + $delay + 3;
my $min_ok = $global_timeout - $delay;

my $pool = AnyEvent::Pg::Pool->new({host   => 'localhost',
                                    port   => $port + 123,
                                    dbname => 'rominadb',
                                    user   => 'albano'},
                                   global_timeout     => $global_timeout,
                                   timeout            => $timeout,
                                   connection_retries => 1000,
                                   on_connect_error   => sub { $cv->send });

# Pool object would not try to connect unless some query is queued
push @w, $pool->push_query(query => "select now()");

my $start = time;
$timer = AE::timer $max_ok + 2, 0, sub {
    diag("timer callback called!");
    $cv->send
};

$cv->recv;
my $elapsed = time - $start;

ok($elapsed >= $min_ok, "retried for the given time")
    or diag ("min_ok: $min_ok, elapsed: $elapsed");
ok($elapsed <= $max_ok, "connection aborted after the given global_timeout")
    or diag ("max_ok: $max_ok, elapsed: $elapsed");

undef $pool;
undef @w;

