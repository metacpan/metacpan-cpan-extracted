package Cisco::SNMP::ProxyPing;

##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use strict;
use warnings;

use Net::SNMP qw(:asn1);
use Cisco::SNMP;

our $VERSION = $Cisco::SNMP::VERSION;

our @ISA = qw(Cisco::SNMP);

use Sys::Hostname;
use Socket qw(AF_INET);

# use Net::IPv6Addr;
my $HAVE_Net_IPv6Addr = 0;
if ( $Socket::VERSION >= 1.94 ) {
    eval "use Net::IPv6Addr 0.2";
    if ( !$@ ) {
        $HAVE_Net_IPv6Addr = 1;
    }
}

my $AF_INET6 = eval { Socket::AF_INET6() };

##################################################
# Start Public Module
##################################################

sub _ppOID {
    return '1.3.6.1.4.1.9.9.16.1.1.1';
}

sub proxy_ping {
    my $self = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %params = (
        count => 1,
        size  => 64,
        wait  => 1
    );

    my %args;
    if ( @_ == 1 ) {
        ( $params{host} ) = @_;
    } else {
        %args = @_;
        for ( keys(%args) ) {
            if ( (/^-?host(?:name)?$/i) || (/^-?dest(?:ination)?$/i) ) {
                $params{host} = $args{$_};
            } elsif (/^-?size$/i) {
                if ( $args{$_} =~ /^\d+$/ ) {
                    $params{size} = $args{$_};
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid size `$args{$_}'";
                    return undef;
                }
            } elsif (/^-?family$/i) {
                if ( $args{$_}
                    =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/ ) {
                    if ( $args{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/ ) {
                        $params{family} = AF_INET;
                    } else {
                        $params{family} = $AF_INET6;
                    }
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid family `$args{$_}'";
                    return undef;
                }
            } elsif (/^-?count$/i) {
                if ( $args{$_} =~ /^\d+$/ ) {
                    $params{count} = $args{$_};
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid count `$args{$_}'";
                    return undef;
                }
            } elsif ( (/^-?wait$/i) || (/^-?timeout$/i) ) {
                if ( $args{$_} =~ /^\d+$/ ) {
                    $params{wait} = $args{$_};
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid wait time `$args{$_}'";
                    return undef;
                }
            } elsif (/^-?vrf(?:name)?$/i) {
                $params{vrf} = $args{$_};
            }
        }
    }
    my $pp;
    $pp->{_params_} = \%params;

    # host must be defined
    if ( not defined $params{host} ) {
        $params{host} = hostname;
    }

    # inherit from new()
    if ( not defined $params{family} ) {
        $params{family} = $self->{family};
    }

    # resolve host our way
    if (defined(
            my $ret = Cisco::SNMP::_resolv( $params{host}, $params{family} )
        )
      ) {
        $params{host}   = $ret->{addr};
        $params{family} = $ret->{family};
    } else {
        return undef;
    }

    my $instance = int( rand(1024) + 1024 );

    # Prepare object by clearing row
    my $response
      = $session->set_request( _ppOID() . '.16.' . $instance, INTEGER, 6 );
    if ( not defined $response ) {
        $Cisco::SNMP::LASTERROR = "proxy ping NOT SUPPORTED";
        return undef;
    }

    # Convert destination to Hex equivalent
    my $dest;
    if ( $params{family} == AF_INET ) {
        for ( split( /\./, $params{host} ) ) {
            $dest .= sprintf( "%02x", $_ );
        }
    } else {
        if ($HAVE_Net_IPv6Addr) {
            my $addr = Net::IPv6Addr->new( $params{host} );
            my @dest = $addr->to_array;
            $dest .= join '', $_ for (@dest);
        } else {
            $Cisco::SNMP::LASTERROR
              = "Socket > 1.94 and Net::IPv6Addr required";
            return undef;
        }
    }

    # ciscoPingEntryStatus (5 = createAndWait, 6 = destroy)
    $response
      = $session->set_request( _ppOID() . '.16.' . $instance, INTEGER, 6 );
    $response
      = $session->set_request( _ppOID() . '.16.' . $instance, INTEGER, 5 );

    # ciscoPingEntryOwner (<anyname>)
    $response = $session->set_request( _ppOID() . '.15.' . $instance,
        OCTET_STRING, __PACKAGE__ );

    # ciscoPingProtocol (1 = IP, 20 = IPv6)
    $response = $session->set_request( _ppOID() . '.2.' . $instance,
        INTEGER, ( $params{family} == AF_INET ) ? 1 : 20 );
    if ( not defined $response ) {
        $Cisco::SNMP::LASTERROR
          = "Device does not support ciscoPingProtocol 20 (IPv6)";
        return undef;
    }

    # ciscoPingAddress (NOTE: hex string, not regular IP)
    $response = $session->set_request( _ppOID() . '.3.' . $instance,
        OCTET_STRING, pack( 'H*', $dest ) );

    # ciscoPingPacketTimeout (in ms)
    $response = $session->set_request( _ppOID() . '.6.' . $instance,
        INTEGER32, $params{wait} * 100 );

    # ciscoPingDelay (Set gaps (in ms) between successive pings)
    $response = $session->set_request( _ppOID() . '.7.' . $instance,
        INTEGER32, $params{wait} * 100 );

    # ciscoPingPacketCount
    $response = $session->set_request( _ppOID() . '.4.' . $instance,
        INTEGER, $params{count} );

    # ciscoPingPacketSize (protocol dependent)
    $response = $session->set_request( _ppOID() . '.5.' . $instance,
        INTEGER, $params{size} );

    if ( exists $params{vrf} ) {

        # ciscoPingVrfName (<name>)
        $response = $session->set_request( _ppOID() . '.17.' . $instance,
            OCTET_STRING, $params{vrf} );
    }

    # Verify ping is ready (ciscoPingEntryStatus = 2)
    $response = $session->get_request( _ppOID() . '.16.' . $instance );
    if ( defined $response->{_ppOID() . '.16.' . $instance} ) {
        if ( $response->{_ppOID() . '.16.' . $instance} != 2 ) {
            $Cisco::SNMP::LASTERROR = "Ping not ready";
            return undef;
        }
    } else {
        $Cisco::SNMP::LASTERROR = "proxy ping NOT SUPPORTED (after setup)";
        return undef;
    }

    # ciscoPingEntryStatus (1 = activate)
    $response
      = $session->set_request( _ppOID() . '.16.' . $instance, INTEGER, 1 );

    # Wait sample interval
    sleep $params{wait};

    # Get results
    $response = $session->get_table( _ppOID() );
    $pp->{Sent}     = $response->{_ppOID() . '.9.' . $instance}  || 0;
    $pp->{Received} = $response->{_ppOID() . '.10.' . $instance} || 0;
    $pp->{Minimum}  = $response->{_ppOID() . '.11.' . $instance} || 0;
    $pp->{Average}  = $response->{_ppOID() . '.12.' . $instance} || 0;
    $pp->{Maximum}  = $response->{_ppOID() . '.13.' . $instance} || 0;

    # destroy entry
    $response
      = $session->set_request( _ppOID() . '.16.' . $instance, INTEGER, 6 );
    return bless $pp, $class;
}

sub ppSent {
    my $self = shift;
    return $self->{Sent};
}

sub ppReceived {
    my $self = shift;
    return $self->{Received};
}

sub ppMinimum {
    my $self = shift;
    return $self->{Minimum};
}

sub ppAverage {
    my $self = shift;
    return $self->{Average};
}

sub ppMaximum {
    my $self = shift;
    return $self->{Maximum};
}

##################################################
# End Public Module
##################################################

1;

__END__

##################################################
# Start POD
##################################################

=head1 NAME

Cisco::SNMP::ProxyPing - Proxy Ping Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::ProxyPing;

=head1 DESCRIPTION

=head2 Proxy Ping

The following methods are for proxy ping.  These methods implement the
C<CISCO-PING-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::ProxyPing object

  my $cm = Cisco::SNMP::ProxyPing->new([OPTIONS]);

Create a new B<Cisco::SNMP::ProxyPing> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 proxy_ping() - execute proxy ping

  my $ping = $cm->proxy_ping([OPTIONS]);

Send proxy ping from the object defined in C<$cm> to the provided
destination.  Called with no options, sends the proxy ping to the
localhost.  Called with one argument, interpreted as the destination
to proxy ping.  Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -count     Number of pings to send                1
  -family    Address family IPv4/IPv6               [Inherit from new()]
               Valid values for IPv4:
                 4, v4, ip4, ipv4, AF_INET (constant)
               Valid values for IPv6:
                 6, v6, ip6, ipv6, AF_INET6 (constant)
  -host      Destination to send proxy ping to      (localhost)
  -size      Size of the ping packets in bytes      64
  -vrf       VRF name to source pings from          [none]
  -wait      Time to wait for replies in seconds    1

A hostname value for B<host> will be resolved to IPv4/v6 based on B<family>.
B<Family> is inherited from the value set in new() but can be overriden.
Providing a numeric address will also self-determine the IPv4/v6 address.

Allows the following accessors to be called.

=head3 ppSent() - return number of pings sent

  $ping->ppSent();

Return the number of pings sent in the current proxy ping execution.

=head3 ppReceived() - return number of pings received

  $ping->ppReceived();

Return the number of pings received in the current proxy ping execution.

=head3 ppMinimum() - return minimum round trip time

  $ping->ppMinimum();

Return the minimum round trip time in milliseconds of pings sent and
received in the current proxy ping execution.

=head3 ppAverage() - return average round trip time

  $ping->ppAverage();

Return the average round trip time in milliseconds of pings sent and
received in the current proxy ping execution.

=head3 ppMaximum() - return maximum round trip time

  $ping->ppMaximum();

Return the maximum round trip time in milliseconds of pings sent and
received in the current proxy ping execution.

=head1 INHERITED METHODS

The following are inherited methods.  See B<Cisco::SNMP> for more information.

=over 4

=item B<close>

=item B<error>

=item B<session>

=back

=head1 EXPORT

None by default.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
C<bin> install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut
