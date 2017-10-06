package Cisco::SNMP::ARP;

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

sub _arpOID {
    return '.1.3.6.1.2.1.4.22.1';
}

sub arpOIDs {
    return qw(IfIndex PhysAddress NetAddress Type);
}

sub arp_clear {
    my $self = shift;
    my ( $idx, $ip ) = @_;

    if ( not defined $idx ) {
        $Cisco::SNMP::LASTERROR = "ifIndex required";
        return undef;
    } elsif ( $idx !~ /^\d+$/ ) {
        $Cisco::SNMP::LASTERROR = "Invalid ifIndex `$idx'";
        return undef;
    }
    if ( not defined $ip ) {
        $Cisco::SNMP::LASTERROR = "IP address required";
        return undef;
    } elsif ( $ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
        $Cisco::SNMP::LASTERROR = "Invalid IP Address `$ip'";
        return undef;
    }

    my $s = $self->session;
    my $r = $s->set_request( _arpOID() . ".4.$idx.$ip", INTEGER, 2 );
    if ( not defined $r ) {
        $Cisco::SNMP::LASTERROR = $s->error;
        return undef;
    }
    return $r->{_arpOID() . ".4.$idx.$ip"};
}

sub arp_info {
    my $self = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my @ARPKEYS = arpOIDs();
    for my $oid ( 0 .. $#ARPKEYS ) {
        $ret{$ARPKEYS[$oid]} = Cisco::SNMP::_snmpwalk( $session,
            _arpOID() . '.' . ( $oid + 1 ) );
        if ( not defined $ret{$ARPKEYS[$oid]} ) {
            $Cisco::SNMP::LASTERROR = "Cannot get ARP `$ARPKEYS[$oid]' info";
            return undef;
        }
    }

    my %ArpType = (
        1 => 'OTHER',
        2 => 'INVALID',
        3 => 'DYNAMIC',
        4 => 'STATIC'
    );
    my @ArpInfo;
    for my $arp ( 0 .. $#{$ret{$ARPKEYS[0]}} ) {
        my %ArpInfoHash;
        for ( 0 .. $#ARPKEYS ) {
            if ( $_ == 1 ) {
                $ArpInfoHash{$ARPKEYS[$_]}
                  = ( $ret{$ARPKEYS[$_]}->[$arp] =~ /^\0/ )
                  ? unpack( 'H12', $ret{$ARPKEYS[$_]}->[$arp] )
                  : ( ( $ret{$ARPKEYS[$_]}->[$arp] =~ /^0x/ )
                    ? substr( $ret{$ARPKEYS[$_]}->[$arp], 2 )
                    : $ret{$ARPKEYS[$_]}->[$arp] );
            } elsif ( $_ == 3 ) {
                $ArpInfoHash{$ARPKEYS[$_]}
                  = exists( $ArpType{$ret{$ARPKEYS[$_]}->[$arp]} )
                  ? $ArpType{$ret{$ARPKEYS[$_]}->[$arp]}
                  : $ret{$ARPKEYS[$_]}->[$arp];
            } else {
                $ArpInfoHash{$ARPKEYS[$_]} = $ret{$ARPKEYS[$_]}->[$arp];
            }
        }
        push @ArpInfo, \%ArpInfoHash;
    }
    return bless \@ArpInfo, $class;
}

for ( arpOIDs() ) {
    Cisco::SNMP::_mk_accessors_array_1( 'arp', $_ );
}

no strict 'refs';

# get_ direct
my @OIDS = arpOIDs();
for my $o ( 0 .. $#OIDS ) {
    *{"get_arp" . $OIDS[$o]} = sub {
        my $self = shift;
        my ( $val1, $val2 ) = @_;

        if ( not defined $val1 ) { $val1 = 1 }
        if ( not defined $val2 ) { $val2 = '1.1.1.1' }
        my $s = $self->session;
        my $r = $s->get_request( varbindlist =>
              [_arpOID() . '.' . ( $o + 1 ) . '.' . "$val1.$val2"] );
        return $r->{_arpOID() . '.' . ( $o + 1 ) . '.' . "$val1.$val2"};
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

Cisco::SNMP::ARP - ARP Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::ARP;

=head1 DESCRIPTION

The following methods are for ARP cache.  These methods
implement the C<ipNetToMediaTable> object of C<RFC1213-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::ARP object

  my $cm = Cisco::SNMP::ARP->new([OPTIONS]);

Create a new B<Cisco::SNMP::ARP> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 arpOIDs() - return OID names

  my @arpOIDs = $cm->arpOIDs();

Return list of ARP MIB object ID names.

=head2 arp_clear() - clear ARP entry

  $cm->arp_clear(ifIndex,IP);

Clear the C<DYNAMIC> ARP entry at interface index C<ifIndex> 
for IP address C<IP>.  Returns undefined on error.

=head2 arp_info() - return arp cache info

  my $arpinfo = $cm->arp_info();

Populate a data structure with ARP information.  If successful,
returns a pointer to an array containing ARP information.

  $arpinfo->[0]->{'IfIndex', 'PhysAddress', ...}
  $arpinfo->[1]->{'IfIndex', 'PhysAddress', ...}
  ...
  $arpinfo->[n]->{'IfIndex', 'PhysAddress', ...}

Allows the following accessors to be called.

=head3 arpIfIndex() - return ARP interface index

  $arpinfo->arpIfIndex([#]);

Return the interface index of the ARP at index '#'.  Defaults to 0.

=head3 arpPhysAddress() - return ARP physical address count

  $arpinfo->arpPhysAddress([#]);

Return the physical address of the ARP at index '#'.  Defaults to 0.

=head3 arpNetAddress() - return ARP network address count

  $arpinfo->arpNetAddress([#]);

Return the network address of the ARP at index '#'.  Defaults to 0.

=head3 arpType() - return ARP type

  $arpinfo->arpType([#]);

Return the type of the ARP at index '#'.  Defaults to 0.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::ARP> object 
directly to access the values directly.

=over 4

=item B<get_arpIfIndex> (i,a)

=item B<get_arpPhysAddress> (i,a)

=item B<get_arpNetAddress> (i,a)

=item B<get_arpType> (i,a)

Get ARP OIDs where (i) is the interface index and (a) is the IP address.  
If (l,s) not provided, uses 0.

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
