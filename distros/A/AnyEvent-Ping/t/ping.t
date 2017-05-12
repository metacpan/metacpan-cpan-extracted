#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use AnyEvent;

# TODO: determinate local address and broadcast address

plan skip_all => 'You can run tests just as root' if $<;

use_ok 'AnyEvent::Ping';

my $ping = new_ok 'AnyEvent::Ping' => [
    timeout    => 1,
    on_prepare => \&on_prepare
];

subtest 'ping 127.0.0.1' => sub {
    my $result;
    my $cv = AnyEvent->condvar;

    $ping->ping(
        '127.0.0.1',
        2,
        sub {
            my $lres = shift;

            $result = $lres;

            $cv->send;
        }
    );

    $cv->recv;

    is_deeply $result, [['OK', $result->[0][1]], ['OK', $result->[1][1]]],
      'ping 127.0.0.1';

    done_testing;
};

subtest 'check two concurrent ping' => sub {
    my $cv = AnyEvent->condvar;
    my @res;

    my $ping_cb = sub {
        my $res = shift;
        push @res, $res;
        $cv->send if @res >= 2;
    };

    $ping->ping('127.0.0.1', 4, $ping_cb);
    $ping->ping('127.0.0.1', 4, $ping_cb);

    $cv->recv;

    is $res[0][0][0], 'OK', 'first concurrent ping ok';
    is $res[1][0][0], 'OK', 'second concurrent ping ok';

    done_testing;
};

subtest 'ping broadcast' => sub {
    my $result;
    my $cv = AnyEvent->condvar;

    $ping->ping(
        '127.255.255.255',
        2,
        sub {
            my $lres = shift;

            $result = $lres;

            $cv->send;
        }
    );

    $cv->recv;

    if ( $^O ne 'MSWin32' ){
        is_deeply $result, [['ERROR', $result->[0][1]]],
            'error reply on ping 127.255.255.255';
    }
    else{
        is $result->[0][0], 'TIMEOUT', 
            '[Win32] timeout reply on ping 127.255.255.255';
    }

    done_testing;
};

subtest 'force end' => sub {
    my $ping = new_ok 'AnyEvent::Ping';
    my $cv = AnyEvent->condvar;

    my $long_times = 1000;
    my $long_ping_result;

    my $short_ping_cb = sub {
        ok not(defined($long_ping_result)), 'long ping is still performing'; 
        $cv->send;
        $ping->end;
    };
    my $long_ping_cb = sub {
        $long_ping_result = shift;
    };

    $ping->ping('127.0.0.1', 4,    $short_ping_cb);
    $ping->ping('127.0.0.1', $long_times, $long_ping_cb);

    $cv->recv;

    is $long_ping_result->[0][0], 'OK', 'unfinished data returned';
    ok scalar(@$long_ping_result) < $long_times, 'unifinished data is unfinished';

    done_testing;
};

subtest 'preparation socket' => sub {
    our $preparation_socket;
    isa_ok($preparation_socket, 'IO::Socket');
};

subtest 'data generation' => sub {
    my $size = 20;
    my $data = AnyEvent::Ping::generate_data_random(20);

    is length($data), $size, 'random data generated right size';
};

$ping->end;

done_testing;
exit;

sub on_prepare {
    our $preparation_socket = shift;
}
