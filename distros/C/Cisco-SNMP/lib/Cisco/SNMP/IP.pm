package Cisco::SNMP::IP;

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

##################################################
# Start Public Module
##################################################

sub _ipOID {
    return '.1.3.6.1.2.1.4';
}

sub ipOIDs {
    return qw(
      Forwarding DefaultTTL InReceives InHdrErrors InAddrErrors
      ForwDatagrams InUnknownProtos InDiscards InDelivers OutRequests
      OutDiscards OutNoRoutes ReasmTimeout ReasmReqds ReasmOKs
      ReasmFails FragOKs FragFails FragCreates
    );
}

sub addrOIDs {
    return qw(Addr IfIndex NetMask BcastAddr ReasmMaxSize);
}

sub routeOIDs {
    return qw(
      Dest IfIndex Metric1 Metric2 Metric3
      Metric4 NextHop Type Proto Age
      Mask Metric5 Info
    );
}

sub ip_info {
    my ( $self, $arg ) = @_;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my @IPKEYS = ipOIDs();
    for my $oid ( 0 .. $#IPKEYS ) {
        $ret{$IPKEYS[$oid]}
          = Cisco::SNMP::_snmpwalk( $session, _ipOID() . '.' . ( $oid + 1 ) );
        if ( not defined $ret{$IPKEYS[$oid]} ) {
            $Cisco::SNMP::LASTERROR = "Cannot get IP `$IPKEYS[$oid]' info";
            return undef;
        }
    }

    my %ForType = (
        1 => 'forwarding',
        2 => 'not-forwarding'
    );
    my @IpInfo;
    for my $ip ( 0 .. $#{$ret{$IPKEYS[0]}} ) {
        my %IpInfoHash;
        for ( 0 .. $#IPKEYS ) {
            if ( $_ == 0 ) {
                $IpInfoHash{$IPKEYS[$_]}
                  = exists( $ForType{$ret{$IPKEYS[$_]}->[$ip]} )
                  ? $ForType{$ret{$IPKEYS[$_]}->[$ip]}
                  : $ret{$IPKEYS[$_]}->[$ip];
            } else {
                $IpInfoHash{$IPKEYS[$_]} = $ret{$IPKEYS[$_]}->[$ip];
            }
        }
        push @IpInfo, \%IpInfoHash;
    }
    return bless \@IpInfo, $class;
}

for ( ipOIDs() ) {
    Cisco::SNMP::_mk_accessors_array_1( 'ip', $_ );
}

sub ip_forwardingOn {
    return set_ipForwarding( shift, 1 );
}

sub ip_forwardingOff {
    return set_ipForwarding( shift, 2 );
}

sub addr_info {
    my ( $self, $arg ) = @_;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my @ADDRKEYS = addrOIDs();
    for my $oid ( 0 .. $#ADDRKEYS ) {
        $ret{$ADDRKEYS[$oid]} = Cisco::SNMP::_snmpwalk( $session,
            _ipOID() . '.20.1.' . ( $oid + 1 ) );
        if ( not defined $ret{$ADDRKEYS[$oid]} ) {
            $Cisco::SNMP::LASTERROR
              = "Cannot get address `$ADDRKEYS[$oid]' info";
            return undef;
        }
    }

    my %AddrInfo;
    for my $ip ( 0 .. $#{$ret{$ADDRKEYS[0]}} ) {
        my %AddrInfoHash;
        for ( 0 .. $#ADDRKEYS ) {
            $AddrInfoHash{$ADDRKEYS[$_]} = $ret{$ADDRKEYS[$_]}->[$ip];
        }
        push @{$AddrInfo{$ret{$ADDRKEYS[1]}->[$ip]}}, \%AddrInfoHash;
    }
    return bless \%AddrInfo, $class;
}

for ( addrOIDs() ) {
    Cisco::SNMP::_mk_accessors_hash_2( 'if', 'addr', $_ );
}

sub route_info {
    my ( $self, $arg ) = @_;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my @ROUTEKEYS = routeOIDs();
    for my $oid ( 0 .. $#ROUTEKEYS ) {
        $ret{$ROUTEKEYS[$oid]} = Cisco::SNMP::_snmpwalk( $session,
            _ipOID() . '.21.1.' . ( $oid + 1 ) );
        if ( not defined $ret{$ROUTEKEYS[$oid]} ) {
            $Cisco::SNMP::LASTERROR
              = "Cannot get route `$ROUTEKEYS[$oid]' info";
            return undef;
        }
    }

    my %RouteType = (
        1 => 'other',
        2 => 'invalid',
        3 => 'direct',
        4 => 'indirect'
    );
    my %RouteProto = (
        1  => 'other',
        2  => 'local',
        3  => 'netmgmt',
        4  => 'icmp',
        5  => 'egp',
        6  => 'ggp',
        7  => 'hello',
        8  => 'rip',
        9  => 'is-is',
        10 => 'es-is',
        11 => 'ciscoIgrp',
        12 => 'bbnSpfIgp',
        13 => 'ospf',
        14 => 'bgp'
    );
    my @RouteInfo;
    for my $ip ( 0 .. $#{$ret{$ROUTEKEYS[0]}} ) {
        my %RouteInfoHash;
        for ( 0 .. $#ROUTEKEYS ) {
            if ( $_ == 8 ) {
                $RouteInfoHash{$ROUTEKEYS[$_]}
                  = exists( $RouteType{$ret{$ROUTEKEYS[$_]}->[$ip]} )
                  ? $RouteType{$ret{$ROUTEKEYS[$_]}->[$ip]}
                  : $ret{$ROUTEKEYS[$_]}->[$ip];
            } elsif ( $_ == 9 ) {
                $RouteInfoHash{$ROUTEKEYS[$_]}
                  = exists( $RouteProto{$ret{$ROUTEKEYS[$_]}->[$ip]} )
                  ? $RouteProto{$ret{$ROUTEKEYS[$_]}->[$ip]}
                  : $ret{$ROUTEKEYS[$_]}->[$ip];
            } else {
                $RouteInfoHash{$ROUTEKEYS[$_]} = $ret{$ROUTEKEYS[$_]}->[$ip];
            }
        }
        push @RouteInfo, \%RouteInfoHash;
    }
    return bless \@RouteInfo, $class;
}

for ( routeOIDs() ) {
    Cisco::SNMP::_mk_accessors_array_1( 'route', $_ );
}

no strict 'refs';

# get_ direct
my @OIDS = ipOIDs();
for my $o ( 0 .. $#OIDS ) {
    *{"get_ip" . $OIDS[$o]} = sub {
        my $self = shift;

        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_ipOID() . '.' . ( $o + 1 ) . '.0'] );
        return $r->{_ipOID() . '.' . ( $o + 1 ) . '.0'};
      }
}

@OIDS = addrOIDs();
for my $o ( 0 .. $#OIDS ) {
    *{"get_addr" . $OIDS[$o]} = sub {
        my $self = shift;
        my ($val) = @_;

        if ( not defined $val ) { $val = '0.0.0.0' }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_ipOID() . '.20.1.' . ( $o + 1 ) . '.' . $val] );
        return $r->{_ipOID() . '.20.1.' . ( $o + 1 ) . '.' . $val};
      }
}

@OIDS = routeOIDs();
for my $o ( 0 .. $#OIDS ) {
    *{"get_route" . $OIDS[$o]} = sub {
        my $self = shift;
        my ($val) = @_;

        if ( not defined $val ) { $val = '0.0.0.0' }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_ipOID() . '.21.1.' . ( $o + 1 ) . '.' . $val] );
        return $r->{_ipOID() . '.21.1.' . ( $o + 1 ) . '.' . $val};
      }
}

# set_ direct
@OIDS = ipOIDs();
for my $o ( 0 .. 1 ) {
    my $def = 1;
    if ( $o == 1 ) { $def = 255 }
    *{"set_ip" . $OIDS[$o]} = sub {
        my $self = shift;
        my ($val) = @_;
        if ( not defined $val ) { $val = $def }
        my $s = $self->session;
        my $r = $s->set_request( _ipOID() . '.' . ( $o + 1 ) . '.0', INTEGER,
            $val );
        if ( not defined $r ) {
            $Cisco::SNMP::LASTERROR = $s->error;
            return;
        } else {
            return $r->{_ipOID() . '.' . ( $o + 1 ) . '.0'};
        }
      }
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

Cisco::SNMP::IP - IP Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::IP;

=head1 DESCRIPTION

The following methods are for IP management.  These methods
implement the C<IP-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::IP object

  my $cm = Cisco::SNMP::IP->new([OPTIONS]);

Create a new B<Cisco::SNMP::IP> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 ipOIDs() - return OID names

  my @ipOIDs = $cm->ipOIDs();

Return list of IP MIB object ID names.

=head2 addrOIDs() - return OID names

  my @addrOIDs = $cm->addrOIDs();

Return list of IP address MIB object ID names.

=head2 routeOIDs() - return OID names

  my @routeOIDs = $cm->routeOIDs();

Return list of route MIB object ID names.

=head2 ip_info() - return IP info for device

  my $ips = $cm->ip_info();

Populate a data structure with the IP information for device.  

Allows the following accessors to be called.

=head3 ipForwarding() - return IP forwarding state

  $ips->ipForwarding();

Return the IP forwarding state of the device.

=head3 ipDefaultTTL() - return IP default ttl

  $ips->ipDefaultTTL();

Return the IP default time to live of the device.

=head3 ipInReceives() - return IP in receives

  $ips->ipInReceives();

Return the IP in receives of the device.

=head3 ipInHdrErrors() - return IP in hardware errors

  $ips->ipInHdrErrors();

Return the IP in hardware errors of the device.

=head3 ipInAddrErrors() - return IP in address errors state

  $ips->ipInAddrErrors();

Return the IP in address errors of the device.

=head3 ipForwDatagrams() - return IP forward datagrams

  $ips->ipForwDatagrams();

Return the IP forward datagrams of the device.

=head3 InUnknownProtos() - return IP unknown protocols

  $ips->InUnknownProtos();

Return the IP unknown protocols of the device.

=head3 ipInDiscards() - return IP in discards

  $ips->ipInDiscards();

Return the IP in discards of the device.

=head3 ipInDelivers() - return IP in delivers state

  $ips->ipInDelivers();

Return the IP in delivers of the device.

=head3 ipOutRequests() - return IP out requests

  $ips->ipOutRequests();

Return the IP out requests of the device.

=head3 ipOutDiscards() - return IP out discards

  $ips->ipOutDiscards();

Return the IP out discards of the device.

=head3 ipOutNoRoutes() - return IP out no routes

  $ips->ipOutNoRoutes();

Return the IP out no routes of the device.

=head3 ipReasmTimeout() - return IP reassembly timeout

  $ips->ipReasmTimeout();

Return the IP reassembly timeout of the device.

=head3 ipReasmReqds() - return IP reassembly required

  $ips->ipReasmReqds();

Return the IP reassembly required of the device.

=head3 ipReasmOKs() - return IP reassembly OK

  $ips->ipReasmOKs();

Return the IP reassembly OK of the device.

=head3 ipReasmFails() - return IP reassembly fails

  $ips->ipReasmFails();

Return the IP reassembly fails of the device.

=head3 ipFragOKs() - return IP fragments OK

  $ips->ipFragOKs();

Return the IP fragments OK of the device.

=head3 ipFragFails() - return IP fragment fails

  $ips->ipFragFails();

Return the IP fragment fails of the device.

=head3 ipFragCreates() - return IP fragment creates

  $ips->ipFragCreates();

Return the IP fragment creates of the device.

=head2 ip_forwardingOn - enable IP forwarding

  $cm->ip_forwardingOn;

Enable IP forwarding (C<ip routing> command).

=head2 ip_forwardingOff - disable IP forwarding

  $cm->ip_forwardingOff;

Disable IP forwarding (C<no ip routing> command).

=head2 addr_info() - return IP address info for interfaces

  my $addrs = $cm->addr_info();

Populate a data structure with the IP information per interface.
If successful, returns a pointer to a hash containing interface IP
information.

  $addrs->{1}->[0]->{'Addr', 'IfIndex, 'NetMask', ...}
               [1]->{'Addr', 'IfIndex, 'NetMask', ...}
               ...
  ...
  $addrs->{n}->[0]->{'Addr', 'IfIndex, 'NetMask', ...}

First hash value is the interface ifIndex, next array is the list of
current IP information per the interface ifIndex.

Allows the following accessors to be called.

=head3 addrAddr() - return IP address

  $addrs->addrAddr([$if[,$ip]]);

Return the address of the IP on interface $if, IP address index $ip.  
Defaults to 0.

=head3 addrIfIndex() - return IP address interface index

  $addrs->addrIfIndex([$if[,$ip]]);

Return the interface index of the IP on interface $if, IP address index $ip.  
Defaults to 0.

=head3 addrNetMask() - return IP address mask

  $addrs->addrNetMask([$if[,$ip]]);

Return the mask of the IP on interface $if, IP address index $ip.  
Defaults to 0.

=head3 addrBcastAddr() - return brodcast address

  $addrs->addrBcastAddr([$if[,$ip]]);

Return the broadcast address of the IP on interface $if, IP address index $ip.  
Defaults to 0.

=head3 addrReasmMaxSize() - return reassembly max size

  $addrs->addrReasmMaxSize([$if[,$ip]]);

Return the reassembly max size of the IP on interface $if, IP address index $ip.  
Defaults to 0.

=head2 route_info() - return route info

  my $route = $cm->route_info();

Populate a data structure with the route information for the device.  
If successful, returns a pointer to a hash containing route information.

  $route->[0]->{'Dest', 'IfIndex, 'Metric1', ...}
          [1]->{'Dest', 'IfIndex, 'Metric1', ...}
          ...
  ...
  $route->[0]->{'Dest', 'IfIndex, 'Metric1', ...}

Allows the following accessors to be called.

=head3 routeDest() - return route destination

  $route->routeDest($ip);

Return the destination of the route $ip.  Defaults to 0.0.0.0.

=head3 routeIfIndex() - return route interface index

  $route->routeIfIndex($ip);

Return the interface index of the route $ip.  Defaults to 0.0.0.0.

=head3 routeMetric1() - return route metric1 value

  $route->routeMetric1($ip);

Return the metric1 value of the route $ip.  Defaults to 0.0.0.0.

=head3 routeMetric2() - return route metric2 value

  $route->routeMetric2($ip);

Return the metric2 value of the route $ip.  Defaults to 0.0.0.0.

=head3 routeMetric3() - return route metric3 value

  $route->routeMetric3($ip);

Return the metric3 value of the route $ip.  Defaults to 0.0.0.0.

=head3 routeMetric4() - return route metric4 value

  $route->routeMetric4($ip);

Return the metric4 value of the route $ip.  Defaults to 0.0.0.0.

=head3 routeNextHop() - return route next hop

  $route->routeNextHop($ip);

Return the next hop of the route $ip.  Defaults to 0.0.0.0.

=head3 routeType() - return route type

  $route->routeType($ip);

Return the type of the route $ip.  Defaults to 0.0.0.0.

=head3 routeProto() - return route protocol

  $route->routeProto($ip);

Return the protocol of the route $ip.  Defaults to 0.0.0.0.

=head3 routeAge() - return route age

  $route->routeAge($ip);

Return the age of the route $ip.  Defaults to 0.0.0.0.

=head3 routeMask() - return route mask

  $route->routeMask($ip);

Return the mask of the route $ip.  Defaults to 0.0.0.0.

=head3 routeMetric5() - return route metric5 value

  $route->routeMetric5($ip);

Return the metric5 value of the route $ip.  Defaults to 0.0.0.0.

=head3 routeInfo() - return route info

  $route->routeInfo($ip);

Return the info of the route $ip.  Defaults to 0.0.0.0.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::IP> object 
directly to access the values directly.

=over 4

=item B<get_ipForwarding>

=item B<get_ipDefaultTTL>

=item B<get_ipInReceives>

=item B<get_ipInHdrErrors>

=item B<get_ipInAddrErrors>

=item B<get_ipForwDatagrams>

=item B<get_ipInUnknownProtos>

=item B<get_ipInDiscards>

=item B<get_ipInDelivers>

=item B<get_ipOutRequests>

=item B<get_ipOutDiscards>

=item B<get_ipOutNoRoutes>

=item B<get_ipReasmTimeout>

=item B<get_ipReasmReqds>

=item B<get_ipReasmOKs>

=item B<get_ipReasmFails>

=item B<get_ipFragOKs>

=item B<get_ipFragFails>

=item B<get_ipFragCreates>

Get IP OIDs.

=item B<set_ipForwarding>

=item B<set_ipDefaultTTL>

Set IP OIDs.

=item B<get_addrAddr> (ip)

=item B<get_addrIfIndex> (ip)

=item B<get_addrNetMask> (ip)

=item B<get_addrBcastAddr> (ip)

=item B<get_addrReasmMaxSize> (ip)

Get IP address OIDS where (ip) is the IP address.

=item B<get_routeDest> (ip)

=item B<get_routeIfIndex> (ip)

=item B<get_routeMetric1> (ip)

=item B<get_routeMetric2> (ip)

=item B<get_routeMetric3> (ip)

=item B<get_routeMetric4> (ip)

=item B<get_routeNextHop> (ip)

=item B<get_routeType> (ip)

=item B<get_routeProto> (ip)

=item B<get_routeAge> (ip)

=item B<get_routeMask> (ip)

=item B<get_routeMetric5> (ip)

=item B<get_routeInfo> (ip)

Get route OIDS where (ip) is the IP route.

=back

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
