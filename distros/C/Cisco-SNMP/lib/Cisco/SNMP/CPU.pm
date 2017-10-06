package Cisco::SNMP::CPU;

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

sub cpuOIDs {
    return qw(Name 5sec 1min 5min Type);
}

sub cpu_info {
    my $self = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my ( $type, $cpu5min );

    # IOS releases > 12.2(3.5)
    if ((   $cpu5min = Cisco::SNMP::_snmpwalk(
                $session, "1.3.6.1.4.1.9.9.109.1.1.1.1.8"
            )
        )
        and defined $cpu5min->[0]
      ) {
        $type = 3

          # 12.0(3)T < IOS releases < 12.2(3.5)
    } elsif (
        (   $cpu5min = Cisco::SNMP::_snmpwalk(
                $session, "1.3.6.1.4.1.9.9.109.1.1.1.1.5"
            )
        )
        and defined $cpu5min->[0]
      ) {
        $type = 2

          # IOS releases < 12.0(3)T
    } elsif (
        (   $cpu5min
            = Cisco::SNMP::_snmpwalk( $session, "1.3.6.1.4.1.9.2.1.58" )
        )
        and defined $cpu5min->[0]
      ) {
        $type = 1;
    } else {
        $Cisco::SNMP::LASTERROR = "Cannot determine CPU type";
        return undef;
    }

    my %cpuType = (
        1 => 'IOS releases < 12.0(3)T',
        2 => '12.0(3)T < IOS releases < 12.2(3.5)',
        3 => 'IOS releases > 12.2(3.5)'
    );

    my @cpuName;

    # Get multiple CPU names
    if ( $type > 1 ) {
        my $temp = Cisco::SNMP::_snmpwalk( $session,
            "1.3.6.1.4.1.9.9.109.1.1.1.1.2" );
        for ( 0 .. $#{$temp} ) {
            if ( $temp->[$_] == 0 ) {
                $cpuName[$_] = '';
                next;
            }
            if (defined(
                    my $result = $session->get_request(
                        -varbindlist =>
                          ['1.3.6.1.2.1.47.1.1.1.1.7.' . $temp->[$_]]
                    )
                )
              ) {
                $cpuName[$_]
                  = $result->{'1.3.6.1.2.1.47.1.1.1.1.7.' . $temp->[$_]};
            } else {
                $Cisco::SNMP::LASTERROR
                  = "Cannot get CPU name for type `$cpuType{$type}'";
                return undef;
            }
        }
    }

    my ( $cpu5sec, $cpu1min );
    if ( $type == 1 ) {
        $cpu5sec = Cisco::SNMP::_snmpwalk( $session, "1.3.6.1.4.1.9.2.1.56" );
        $cpu1min = Cisco::SNMP::_snmpwalk( $session, "1.3.6.1.4.1.9.2.1.57" );
        $cpu5min = Cisco::SNMP::_snmpwalk( $session, "1.3.6.1.4.1.9.2.1.58" );
    } elsif ( $type == 2 ) {
        $cpu5sec = Cisco::SNMP::_snmpwalk( $session,
            "1.3.6.1.4.1.9.9.109.1.1.1.1.3" );
        $cpu1min = Cisco::SNMP::_snmpwalk( $session,
            "1.3.6.1.4.1.9.9.109.1.1.1.1.4" );
        $cpu5min = Cisco::SNMP::_snmpwalk( $session,
            "1.3.6.1.4.1.9.9.109.1.1.1.1.5" );
    } elsif ( $type == 3 ) {
        $cpu5sec = Cisco::SNMP::_snmpwalk( $session,
            "1.3.6.1.4.1.9.9.109.1.1.1.1.6" );
        $cpu1min = Cisco::SNMP::_snmpwalk( $session,
            "1.3.6.1.4.1.9.9.109.1.1.1.1.7" );
        $cpu5min = Cisco::SNMP::_snmpwalk( $session,
            "1.3.6.1.4.1.9.9.109.1.1.1.1.8" );
    }

    my @CPUInfo;
    for my $cpu ( 0 .. $#{$cpu5min} ) {
        my %CPUInfoHash;
        $CPUInfoHash{Name}   = $cpuName[$cpu];
        $CPUInfoHash{'5sec'} = $cpu5sec->[$cpu];
        $CPUInfoHash{'1min'} = $cpu1min->[$cpu];
        $CPUInfoHash{'5min'} = $cpu5min->[$cpu];
        $CPUInfoHash{Type}   = $cpuType{$type};
        push @CPUInfo, \%CPUInfoHash;
    }
    return bless \@CPUInfo, $class;
}

for ( cpuOIDs() ) {
    Cisco::SNMP::_mk_accessors_array_1( 'cpu', $_ );
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

Cisco::SNMP::CPU - CPU Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::CPU;

=head1 DESCRIPTION

The following methods are for CPU utilization.  These methods
implement the C<CISCO-PROCESS-MIB> and C<OLD-CISCO-SYS-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::CPU object

  my $cm = Cisco::SNMP::CPU->new([OPTIONS]);

Create a new B<Cisco::SNMP::CPU> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 cpuOIDs() - return OID names

  my @cpuOIDS = $cm->cpuOIDS();

Return list of CPU MIB object ID names.

=head2 cpu_info() - return CPU utilization info

  my $cpuinfo = $cm->cpu_info();

Populate a data structure with CPU information.  If successful,
returns pointer to an array containing CPU information.

  $cpuinfo->[0]->{'Name', '5sec', '1min', ...}
  $cpuinfo->[1]->{'Name', '5sec', '1min', ...}
  ...
  $cpuinfo->[n]->{'Name', '5sec', '1min', ...}

Allows the following accessors to be called.

=head3 cpuName() - return CPU name

  $cpuinfo->cpuName([#]);

Return the name of the CPU at index '#'.  Defaults to 0.  This is a 
derived value from C<ENTITY-MIB> not an actual MIB OID.

=head3 cpuType() - return CPU type

  $cpuinfo->cpuType([#]);

Return the type of the CPU at index '#'.  Defaults to 0.  This is a 
derived value, not an actual MIB OID.

=head3 cpu5sec() - return CPU 5sec utilization

  $cpuinfo->cpu5sec([#]);

Return the 5sec utilization of the CPU at index '#'.  Defaults to 0.

=head3 cpu1min() - return CPU 1min utilization

  $cpuinfo->cpu1min([#]);

Return the 1min utilization of the CPU at index '#'.  Defaults to 0.

=head3 cpu5min() - return CPU 5min utilization

  $cpuinfo->cpu5min([#]);

Return the 5min utilization of the CPU at index '#'.  Defaults to 0.

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
