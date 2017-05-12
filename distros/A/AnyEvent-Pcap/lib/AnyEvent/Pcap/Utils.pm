package AnyEvent::Pcap::Utils;
use strict;
use warnings;
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::TCP;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    return $self;
}

sub extract_ip_packet {
    my $self       = shift;
    my $raw_packet = shift;
    my $raw_ip     = NetPacket::Ethernet->decode($raw_packet)->{data};
    my $ip         = NetPacket::IP->decode($raw_ip);
    return $ip;
}

sub extract_tcp_packet {
    my $self       = shift;
    my $raw_packet = shift;
    my $raw_ip     = NetPacket::Ethernet->decode($raw_packet)->{data};
    my $ip         = NetPacket::IP->decode($raw_ip);
    my $raw_tcp    = substr( $ip->{data}, 0, $ip->{len} - ( $ip->{hlen} * 4 ) );
    my $tcp        = NetPacket::TCP->decode($raw_tcp);
    return $tcp;
}

1;
__END__

=head1 NAME

AnyEvent::Pcap::Utils - Utilty class for AnyEvent::Pcap.

=head1 SYNOPSIS

  my $a_pcap;
  $a_pcap = AnyEvent::Pcap->new(
      device         => "eth0",
      filter         => "tcp port 80",
      packet_handler => sub {
          my $header = shift;
          my $packet = shift;
  
          # you can use utils to get an NetPacket::TCP object.
          my $tcp = $a_pcap->utils->extract_tcp_packet($packet);
  
          # and you can get an IP packet, too.
          my $ip = $a_pcap->utils->extract_ip_packet($packet);
  
          # do something....
      }
  );
	

=head1 DESCRIPTION

AnyEvent::Pcap::Utils is a utilty class for AnyEvent::Pcap. 

=head1 METHODS

=over 4

=item new();

=item extract_tcp_packet(I<[RAW_PACKET]>)

return NetPacket::TCP object. see L<NetPacket::TCP>.

=item extract_ip_packet(I<[RAW_PACKET]>)

return NetPacket::IP object. see L<NetPacket::IP>.
 
=back

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<NetPacket::TCP> L<NetPacket::IP>

=cut