package t::lib::Eris::Test;

use strict;
use warnings;
use Test::More       ();
use AnyEvent         ();
use AnyEvent::Handle ();
use AnyEvent::Socket ();
use Import::Into     ();
use Net::EmptyPort   ();
use AnyEvent::eris::Server;
use AnyEvent::eris::Client;

sub import {
    my ( $class, %opts ) = @_;
    my $target           = caller;

    $_->import::into($target) for qw<
        strict warnings
        AnyEvent AnyEvent::Socket AnyEvent::Handle
        AnyEvent::eris::Server AnyEvent::eris::Client
    >;

    Test::More->import::into( $target, %opts );

    {
        no strict 'refs'; ## no critic
        *{"${target}::new_server"} = *new_server;
    }
}

sub new_server {
    my $cv     = AE::cv;
    my $server = AnyEvent::eris::Server->new(
        ListenPort => $ENV{'ERIS_TEST_PORT'} ||
                      Net::EmptyPort::empty_port(),
    );

    return ( $server, $cv );
}

1;
