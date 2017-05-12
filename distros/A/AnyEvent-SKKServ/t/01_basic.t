use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::TCP';
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;

use AnyEvent::SKKServ;

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;

        my $skkserv = AnyEvent::SKKServ->new(port => $port);
        $skkserv->run;

        AE::cv()->recv;
    },
);

my $cv = AE::cv();

tcp_connect '127.0.0.1', $server->port, sub {
    my ($fh) = @_ or die $!;
    my $hdl; $hdl = AnyEvent::Handle->new(
        fh => $fh,
    );

    $hdl->push_write('2');
    $hdl->push_read(regex => qr/\x20/, sub {
        is $_[1], "$AnyEvent::SKKServ::VERSION:anyevent_skkserv ";
    });

    $hdl->push_write('3');
    $hdl->push_read(regex => qr/\x20/, sub {
        is $_[1], 'hostname:addr:...: ';
    });

    $hdl->push_write('9');
    $hdl->push_read(regex => qr/\n/, sub {
        is $_[1], "0\n", 'illegal command';

        undef $hdl;
        $cv->send;
    });
};

$cv->recv;

done_testing;
