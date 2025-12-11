#!/usr/bin/perl

package BACnet::Socket;

use v5.16;

use Future::AsyncAwait;
use IO::Async::Socket;
use IO::Async::Loop;
use Socket qw(unpack_sockaddr_in inet_ntoa pack_sockaddr_in inet_aton);
use Data::Dumper;

use BACnet::Device;

use Scalar::Util 'weaken';

my $BACNET_PORT = 0xBAC0;    # 47808

sub new {
    my ( $class, $device, %args ) = @_;

    weaken { $device };

    my $self = {
        retries => $args{retries} // 3,
        timeout => $args{timeout} // 3,
        loop    => $args{io_loop} // IO::Async::Loop->new,
        debug   => $args{debug},
        stime   => time,           # for debugging timestamps
        device  => $device,
    };
    bless $self, $class;

    $self->{sock} =
      IO::Async::Socket->new( on_recv => sub { $self->_recv(@_) }, );

    $self->loop->add( $self->{sock} );
    $self->sock->bind(
        socktype => 'dgram',
        addr     => $args{addr},
        service  => $args{sport} // 0,
    )->get;    # local bind() does not block

    return $self;
}

sub _debug {
    my ( $self, @msg ) = @_;
    return if !$self->{debug};
    say STDERR sprintf( "+%04ds", time - $self->{stime} ), ' ', @msg;
}

sub _recv {
    my ( $self, $sock, $dgram, $addr ) = @_;

    my ( $port, $ip ) = unpack_sockaddr_in($addr);
    my $ipaddr = inet_ntoa($ip);
    $self->_debug("got packet from $ipaddr:$port");

    my $packet = BACnet::BVLC->parse($dgram);

    # say STDERR Dumper $packet;

    $self->_debug( join( ' ', '< recv', unpack( "(H2)*", $dgram ) ) );

    if ( defined $self->{reader_of}{$addr}
        && _is_response( $self->{reader_of}{$addr}{packet}, $packet ) )
    {
        if ( defined $self->{reader_of}{$addr}{on_response} ) {
            $self->{reader_of}{$addr}{on_response}
              ->( $self->{device}, $packet->{payload}, $port, $ip );
        }
        my $r = delete $self->{reader_of}{$addr};
        $self->loop->unwatch_time( $r->{timer} );
        $r->{future}->done($packet);
        return;
    }

    $self->{device}->_react( $packet, $port, $ip );
}

async sub _send_recv {
    my ( $self, $packet, $ip, $port, %args ) = @_;
    my $data = $packet->data();
    $port //= $BACNET_PORT;
    my $addr = pack_sockaddr_in( $port, inet_aton($ip) );

    my $retries = $args{retries} // $self->{retries};
    while ( $retries-- ) {
        $self->_debug( join( ' ', '> send', unpack( "(H2)*", $data ) ) );
        $self->sock->send( $data, 0, $addr );

        my $ok = 1;

        my $f  = $self->loop->new_future;
        my $id = $self->loop->watch_time(
            after => $args{timeout} // $self->{timeout},
            code  => sub {
                delete $self->{reader_of}{$addr};
                $ok = 0;
                $f->fail("no response from $ip:$port");
            },
        );
        $self->{reader_of}{$addr} = {
            timer       => $id,
            future      => $f,
            packet      => $packet,
            on_response => $args{on_response}
        };
        return $f->get if ( $f->await->is_done && $ok );
    }

    return undef;
}

async sub _send {
    my ( $self, $packet, $ip, $port, %args ) = @_;

    #   my @octets           = map { ord($_) } split //, $ip;
    #   my $source_ip_string = join( '.', @octets );

    #   warn "ip: $source_ip_string, port: $port";
    #   print "get message: ", Dumper($packet), "\n";

    my $data = $packet->data();
    $port //= $BACNET_PORT;
    my $addr = pack_sockaddr_in( $port, inet_aton($ip) );
    $self->sock->send( $data, 0, $addr );
}

sub loop { shift->{loop} }

sub sock { shift->{sock} }

sub _is_response {
    my ( $request, $response ) = @_;

    if (   defined $response->{payload}
        && defined $response->{payload}->{service_choice}
        && defined $response->{payload}->{invoke_id}
        && $response->{payload}->{service_choice} eq
        $request->{payload}->{service_choice}
        && $response->{payload}->{invoke_id} ==
        $request->{payload}->{invoke_id} )
    {
        return 1;
    }
    return 0;
}

1;
