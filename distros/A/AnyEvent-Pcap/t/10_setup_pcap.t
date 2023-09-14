#!perl
use strict;
use warnings;
use Test::More;
use AnyEvent::Pcap;
use NetPacket::ICMP qw< :types >;


my @samples = glob "t/samples/*.dmp";

plan tests => 5 * @samples;


# check that _setup_pcap() works on saved dumps
for my $sample (@samples) {
    my $cv = AnyEvent->condvar;

    my $ae_pcap; $ae_pcap = eval { AnyEvent::Pcap->new(
        device => "file:$sample",
        packet_handler => sub {
            my ($header, $packet) = @_;
            return unless ref $header eq "HASH";

            my $ip = $ae_pcap->utils->extract_ip_packet($packet);
            my $icmp = NetPacket::ICMP->decode($ip->{data});

            ok $icmp->{type} == ICMP_ECHO || $icmp->{type} == ICMP_ECHOREPLY,
                "check that the packet is an ICMP echo or echo-reply";

            $cv->send;
        },
    )};
    is $@, "", "AnyEvent::Pcap->new(...)";

    my $pcap = eval { $ae_pcap->_setup_pcap };
    is $@, "", "\$ae_pcap->_setup_pcap";

    isa_ok $pcap, "pcap_tPtr", 'check that $pcap';
    isa_ok $ae_pcap->fd, "GLOB", 'check that $ae_pcap->fd';

    $ae_pcap->run;
    $cv->recv;
}

