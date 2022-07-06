use strict;
use warnings;
use AnyEvent;
use AnyEvent::Socket;
use Test::More;
use IO::Socket::INET;
use AnyEvent::SNMP::TrapReceiver;
use Socket qw/unpack_sockaddr_in/;

{
	my $cv = AnyEvent->condvar;
    my $trapd = AnyEvent::SNMP::TrapReceiver->new(
        bind => ['localhost', 0],
        cb => sub {
            $cv->send( @_);
        },
    );
	my $port = (unpack_sockaddr_in($trapd->{server}->{fh}->sockname))[0];
	my $client = IO::Socket::INET->new(PeerHost => 'localhost', PeerPort => $port, Proto => 'udp');
    # hard coded v2c trap
    my $raw = pack( 'H*', '3041020101040464656d6fa7360204779778cc0201000201003028300e06082b06010201010300430203d43016060a2b06010603010104010006082b06010603010101');
	send $client, $raw, 0;
	is( $cv->recv->{oid}{'1.3.6.1.2.1.1.3.0'}, 980, "Verify v2c trap content");
}

{
	my $cv = AnyEvent->condvar;
    my $trapd = AnyEvent::SNMP::TrapReceiver->new(
        bind => ['localhost', 0],
        cb => sub {
            $cv->send( @_);
        },
    );
	my $port = (unpack_sockaddr_in($trapd->{server}->{fh}->sockname))[0];
	my $client = IO::Socket::INET->new(PeerHost => 'localhost', PeerPort => $port, Proto => 'udp');
    # hard coded v1 trap
    my $raw = pack( 'H*', '3034020100040464656d6fa429060357060840047f000001020101020101430400e268ea3010300e06032b0601040761626364656667');
	send $client, $raw, 0;
    ok( $cv->recv->{oid}{'1.3.6.1'} eq 'abcdefg', "Verify v1 trap content");
}

done_testing;
