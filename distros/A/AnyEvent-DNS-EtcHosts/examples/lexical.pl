#!/usr/bin/perl

# Example: lexical.pl google.com xmpp-client tcp 4

use v5.14;

use lib 'lib', '../lib';

my $domain  = $ARGV[0] || 'example.com';
my $service = $ARGV[1] || 80;
my $proto   = $ARGV[2] || 'tcp';
my $family  = $ARGV[3] || 0;

require AnyEvent::DNS::EtcHosts;

use AnyEvent::Socket;
use Socket;

say 'Disabled AnyEvent::DNS::EtcHosts';

{
    my $cv = AE::cv;

    AnyEvent::Socket::resolve_sockaddr $domain, $service, $proto, $family, undef, sub {
        say foreach map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_;
        $cv->send;
    };

    $cv->recv;
}

say;
say 'Enabled AnyEvent::DNS::EtcHosts';

{
    my $guard = AnyEvent::DNS::EtcHosts->register;

    my $cv = AE::cv;

    AnyEvent::Socket::resolve_sockaddr $domain, $service, $proto, $family, undef, sub {
        say foreach map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_;
        $cv->send;
    };

    $cv->recv;
}

say;
say 'Disabled AnyEvent::DNS::EtcHosts';

{
    my $cv = AE::cv;

    AnyEvent::Socket::resolve_sockaddr $domain, $service, $proto, $family, undef, sub {
        say foreach map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_;
        $cv->send;
    };

    $cv->recv;
}

