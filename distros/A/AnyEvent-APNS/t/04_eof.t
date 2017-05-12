use strict;
use warnings;
use Test::More;
use Test::TCP;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::APNS;

my $cv;
my $port = empty_port;

my $server = tcp_server undef, $port, sub {
    my ($fh) = @_
        or die $!;

    # close immediately
    close $fh;
};

# without on_eof
$cv = AnyEvent->condvar;

my $apns; $apns = AnyEvent::APNS->new(
    debug_port  => $port,
    certificate => \'',
    private_key => \'',
    on_error    => sub {
        my ($h, $fatal, $msg) = @_;

        like $msg, qr/^Unexpected end-of-file/, 'eof ok';
        $cv->send;
    },
);
$apns->connect;

$cv->recv;


# on_eof
$cv = AnyEvent->condvar;

$apns = AnyEvent::APNS->new(
    debug_port  => $port,
    certificate => \'',
    private_key => \'',
    on_error    => sub {
        my ($h, $fatal, $msg) = @_;
        fail 'on_eof not called: ' . $msg;
        $cv->send;
    },
    on_eof => sub {
        my ($h) = @_;
        pass 'on_eof called ok';
        $cv->send;
    },
);
$apns->connect;

$cv->recv;

done_testing;
