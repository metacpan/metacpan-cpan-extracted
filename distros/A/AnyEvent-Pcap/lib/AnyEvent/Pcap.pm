package AnyEvent::Pcap;
use strict;
use warnings;
use Carp;
use AnyEvent;
use AnyEvent::Pcap::Utils;
use Net::Pcap;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.00002';

__PACKAGE__->mk_accessors($_) for qw(utils device filter packet_handler fd);

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->utils( AnyEvent::Pcap::Utils->new );
    return $self;
}

sub _setup_pcap {
    my $self = shift;

    my $err;
    my $device = $self->device || sub {
        $self->device( Net::Pcap::pcap_lookupdev( \$err ) );
      }
      ->();
    croak $err if $err;

    my $pcap = Net::Pcap::pcap_open_live( $device, 1024, 1, 0, \$err );
    croak $err if $err;

    my ( $address, $netmask );
    Net::Pcap::lookupnet( $device, \$address, \$netmask, \$err );
    croak $err if $err;

    my $filter;
    my $filter_string = $self->filter || sub {
        $self->filter("");
      }
      ->();

    Net::Pcap::compile( $pcap, \$filter, $filter_string, 0, $netmask );
    Net::Pcap::setfilter( $pcap, $filter );

    my $fd = Net::Pcap::fileno($pcap);
    $self->fd($fd);
    return $pcap;
}

sub run {
    my $self = shift;

    my $pcap = $self->_setup_pcap();

    my $packet_handler = $self->packet_handler || sub {
        $self->packet_handler( sub { } );
      }
      ->();

    my $io;
    $io = AnyEvent->io(
        fh   => $self->fd,
        poll => 'r',
        cb   => sub {
            my @pending;
            Net::Pcap::dispatch(
                $pcap, -1,
                sub {
                    my $header = $_[1];
                    my $packet = $_[2];
                    push @{ $_[0] }, ( $header, $packet );
                },
                \@pending
            );
            $packet_handler->( @pending, $io );
        }
    );
}

1;
__END__

=head1 NAME

AnyEvent::Pcap - Net::Pcap wrapper with AnyEvent

=head1 SYNOPSIS

  use AnyEvent::Pcap;

  my $a_pcap;
  $a_pcap = AnyEvent::Pcap->new(
      device         => "eth0",
      filter         => "tcp port 80",
      packet_handler => sub {
          my $header = shift;
          my $packet = shift;
  
          # you can use utils to get an NetPacket::TCP object.
          my $tcp = $a_pcap->utils->extract_tcp_packet($packet);

          # or ...
          $tcp = AnyEvent::Pcap::Utils->extract_tcp_packet($packet); 

          # do something....
      }
  );
  
  $a_pcap->run();
  
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

AnyEvent::Pcap is a Net::Pcap wrapper with AnyEvent.

Also you can use its utils to get NetPacket::IP or NetPacket::TCP object.


=head1 METHODS

=over 4

=item new(I<[%args]>);

  my %args = (
  
      # It will be filled up Net::Pcap::pcap_lookupdev() by default
      device => "eth0",
  
      # Default is NULL
      filter => "tcp port 80",
  
      # set your coderef
      packet_handler => sub {
          my $header = shift;
          my $packet = shift;
  
          # do something....
      }
  );
  
  my $a_pcap = AnyEvent::Pcap->new(%args);

Cteate and return new AnyEvent::Pcap object .

=item utils()

  my $a_pcap = AnyEvent::Pcap->new;
  my $utils  = $a_pcap->utils;
    
You can get an utilty for packet handling. See L<AnyEvent::Pcap::Utils>.

=item run()

  my $a_pcap = AnyEvent::Pcap->new(%args);
  $a_pcap->run;

  AnyEvent->condvar->recv;

Running AnyEvent loop.

=back

=head2 accessor methods

=over 4

=item device(I<[STRING]>)

=item fiilter(I<[STRING]>)

=item packet_handler(I<[CODEREF]>)

=back

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent> L<Net::Pcap>

=cut
