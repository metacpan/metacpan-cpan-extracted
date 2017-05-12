package Cisco::SNMP::System;

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

sub _sysOID {
    return '1.3.6.1.2.1.1'
}

sub sysOIDs {
    return qw(Descr ObjectID UpTime Contact Name Location Services ORLastChange)
}

sub system_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my $response = Cisco::SNMP::_snmpwalk($session, _sysOID());
    if (defined $response) {

        my $sysinfo;
        my @SYSKEYS = sysOIDs();
        for (0..$#SYSKEYS) {
            $sysinfo->{$SYSKEYS[$_]}  = $response->[$_]
        }
        return bless $sysinfo, $class
    } else {
        $Cisco::SNMP::LASTERROR = "Cannot read system MIB";
        return undef
    }
}

sub sysDescr {
    my $self = shift;
    return $self->{Descr}
}

sub sysObjectID {
    my $self = shift;
    return $self->{ObjectID}
}

sub sysUpTime {
    my $self = shift;
    return $self->{UpTime}
}

sub sysContact {
    my $self = shift;
    return $self->{Contact}
}

sub sysName {
    my $self = shift;
    return $self->{Name}
}

sub sysLocation {
    my $self = shift;
    return $self->{Location}
}

sub sysORLastChange {
    my $self = shift;
    return $self->{ORLastChange}
}

sub sysServices {
    my ($self, $arg) = @_;

    if (defined($arg) && ($arg >= 1)) {
        return $self->{Services}
    } else {
        my %Services = (
            1  => 'Physical',
            2  => 'Datalink',
            4  => 'Network',
            8  => 'Transport',
            16 => 'Session',
            32 => 'Presentation',
            64 => 'Application'
        );
        my @Svcs;
        for (sort {$b <=> $a} (keys(%Services))) {
            push @Svcs, $Services{$_} if ($self->{Services} & int($_))
        }
        return \@Svcs
    }
}

sub sysOSVersion {
    my $self = shift;

    if ($self->{Descr} =~ /Version ([^ ,\n\r]+)/) {
        return $1
    } else {
        return "Cannot determine OS Version"
    }
}

no strict 'refs';
# get_ direct
my @OIDS = sysOIDs();
for my $o (0..$#OIDS) {
    *{"get_sys" . $OIDS[$o]} = sub {
        my $self  = shift;

        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_sysOID() . '.' . ($o+1) . '.0']
        );
        return $r->{_sysOID() . '.' . ($o+1) . '.0'}
    }
}

# set_ direct
for my $o (3..5) {
    *{"set_sys" . $OIDS[$o]} = sub {
        my $self  = shift;
        my ($val) = @_;

        if (!defined $val) { $val = '' }
        my $s = $self->session;
        my $r = $s->set_request(
            _sysOID() . '.' . ($o+1) . '.0', OCTET_STRING, $val
        );
        if (!defined $r) {
            $Cisco::SNMP::LASTERROR = $s->error;
            return
        } else {
            return $r->{_sysOID() . '.' . ($o+1) . '.0'}
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

Cisco::SNMP::System - System Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::System;

=head1 DESCRIPTION

The following methods implement the System MIB defined in C<SNMPv2-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::System object

  my $cm = Cisco::SNMP::System->new([OPTIONS]);

Create a new B<Cisco::SNMP::System> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 sysOIDs() - return OID names

  my @sysOIDs = $cm->sysOIDs();

Return list of System MIB object ID names.

=head2 system_info() - populate system info data structure.

  my $sysinfo = $cm->system_info();

Retrieve the system MIB information from the object defined in C<$cm>.

Allows the following accessors to be called.

=head3 sysDescr() - return system description

  $sysinfo->sysDescr();

Return the system description from the system info data structure.

=head3 sysObjectID() - return system object ID

  $sysinfo->sysObjectID();

Return the system object ID from the system info data structure.

=head3 sysUpTime() - return system uptime

  $sysinfo->sysUpTime();

Return the system uptime from the system info data structure.

=head3 sysContact() - return system contact

  $sysinfo->sysContact();

Return the system contact from the system info data structure.

=head3 sysName() - return system name

  $sysinfo->sysName();

Return the system name from the system info data structure.

=head3 sysLocation() - return system location

  $sysinfo->sysLocation();

Return the system location from the system info data structure.

=head3 sysServices() - return system services

  $sysinfo->sysServices([1]);

Return a pointer to an array containing the names of the system
services from the system info data structure.  For the raw number,
use the optional boolean argument.

=head3 sysORLastChange() - return system orlastchange

  $sysinfo->sysORLastChange();

Return the system orlastchange from the system info data structure.

=head3 sysOSVersion() - return system OS version

  $sysinfo->sysOSVersion();

Return the system OS version as parsed from the sysDescr OID.  This is a 
derived value, not an actual MIB OID.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::System> object 
directly to access the values directly.

=over 4

=item B<get_sysDescr>

=item B<get_sysObjectID>

=item B<get_sysUpTime>

=item B<get_sysContact>

=item B<get_sysName>

=item B<get_sysLocation>

=item B<get_sysServices>

=item B<get_sysORLastChange>

Get System OIDs.

=item B<set_sysContact> (string)

=item B<set_sysName> (string)

=item B<set_sysLocation> (string)

Set System OIDs.

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
