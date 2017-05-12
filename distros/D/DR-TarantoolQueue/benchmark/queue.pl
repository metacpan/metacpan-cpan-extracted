#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Encode qw(decode encode);
use Cwd 'cwd';
use File::Spec::Functions 'catfile';
use feature 'state';

use Coro;
use DR::Tarantool ':all';
use DR::Tarantool::StartTest;
use Time::HiRes 'time';
use Data::Dumper;
use Coro::AnyEvent;

my $t = DR::Tarantool::StartTest->run(
    cfg         => catfile(cwd, 'tarantool.cfg'),
    script_dir  => catfile(cwd)
);

sub tnt {
    our $tnt;
    unless(defined $tnt) {
        $tnt = coro_tarantool
            host => 'localhost',
            port => $t->primary_port,
            spaces => {}
        ;
    }
    return $tnt;
};

tnt->ping;

my $done = 0;
my $total_time = 0;
my $total_put = 0;
my $total_take_ack = 0;
my $process = 1;

$SIG{INT} = $SIG{TERM} = sub {
    print "\nSIGING received\n";
    $t->kill unless $process;
    $process = 0;
};


use constant ITERATIONS => 1000;


while($process) {

    my $put_time = 0;
    my $take_ack_time = 0;
    my $start_time = time;
    my (@f, %t);
    for (my $i = 0; $i < ITERATIONS; $i++) {
        push @f => async {
            my $tuple = tnt->call_lua('queue.put',
                [ 0, 'tube', 0, 10, 5, 1, 'task body' ]);
            $t{ $tuple->raw(0) }++;
        };
    }

    $_->join for @f;
    @f = ();
    $put_time = time - $start_time;
    $start_time = time;

    for (my $i = 0; $i < ITERATIONS; $i++) {
        push @f => async {
            my $tuple = tnt->call_lua('queue.take', [ 0, 'tube', 3 ]);
            $t{ $tuple->raw(0) }++ if $tuple;

            tnt->call_lua('queue.ack', [ 0, $tuple->raw(0) ]);
        };

    }

    $_->join for @f;
    @f = ();

    $take_ack_time = time - $start_time;

    my $done_time = $take_ack_time  + $put_time;
    $total_time += $done_time;
    $done += ITERATIONS;

    $total_put += $put_time;
    $total_take_ack += $take_ack_time;

    if (scalar keys %t != ITERATIONS) {
        print "Wrong results count\n";
        last;
    }
    if (ITERATIONS != grep { $_ == 2 } values %t) {
        print "Not all tasks were processed twice\n";
        last;
    }

    printf "\nDone %d sessions in %3.2f seconds (%d r/s, %f s/r)\n",
        $done,
        $total_time,
        $done / $total_time,
        $total_time / $done
    ;

    printf " put: %6d r/s, %1.6f s/r,     take/ack: %6d r/s, %1.6f s/r\n",
        $done / $total_put,
        $total_put / $done,
        $done / $total_take_ack,
        $total_take_ack / $done,
    ;

}

warn $t->log if $ENV{DEBUG};
