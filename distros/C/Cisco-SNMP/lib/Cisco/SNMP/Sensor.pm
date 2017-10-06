package Cisco::SNMP::Sensor;

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

sub _sensOID {
    return '1.3.6.1.4.1.9.9.91.1.1.1.1';
}

sub sensOIDs {
    return qw(Type Scale Precision Value Status ValueTimeStamp
      ValueUpdateRate EntityId);
}

sub sensor_info {
    my $self = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my $OIDS;
    my @SENSKEYS = sensOIDs();

    # -1 because last key (EntityId) isn't an OID; rather, added
    for my $oid ( 0 .. $#SENSKEYS - 1 ) {
        ( $OIDS, $ret{$SENSKEYS[$oid]} )
          = Cisco::SNMP::_snmpwalk( $session,
            _sensOID() . '.' . ( $oid + 1 ) );
        if ( not defined $ret{$SENSKEYS[$oid]} ) {
            $Cisco::SNMP::LASTERROR
              = "Cannot get sensor `$SENSKEYS[$oid]' info";
            return undef;
        }
    }

    # need to record entity index
    for ( @{$OIDS} ) {

        # split the OID at dots
        my @entId = split /\./, $_;

        # take the last value, which is the entity Index equal to value returned
        push @{$ret{$SENSKEYS[$#SENSKEYS]}}, $entId[$#entId];
    }

    my %SensType = (
        1  => 'other',
        2  => 'unknown',
        3  => 'voltsAC',
        4  => 'voltsDC',
        5  => 'amperes',
        6  => 'watts',
        7  => 'hertz',
        8  => 'celsius',
        9  => 'percentRH',
        10 => 'rpm',
        11 => 'cmm',
        12 => 'truthvalue',
        13 => 'specialEnum',
        14 => 'dBm'
    );
    my %SensScale = (
        1  => 'yocto',
        2  => 'zepto',
        3  => 'atto',
        4  => 'femto',
        5  => 'pico',
        6  => 'nano',
        7  => 'micro',
        8  => 'milli',
        9  => 'units',
        10 => 'kilo',
        11 => 'mega',
        12 => 'giga',
        13 => 'tera',
        14 => 'exa',
        15 => 'peta',
        16 => 'zetta',
        17 => 'yotta'
    );
    my %SensStatus = (
        1 => 'ok',
        2 => 'unavailable',
        3 => 'nonoperational'
    );
    my %SensInfo;
    for my $sens ( 0 .. $#{$ret{$SENSKEYS[0]}} ) {
        my %SensInfoHash;
        for ( 0 .. $#SENSKEYS ) {
            if ( $_ == 0 ) {
                $SensInfoHash{$SENSKEYS[$_]}
                  = exists( $SensType{$ret{$SENSKEYS[$_]}->[$sens]} )
                  ? $SensType{$ret{$SENSKEYS[$_]}->[$sens]}
                  : $ret{$SENSKEYS[$_]}->[$sens];
            } elsif ( $_ == 1 ) {
                $SensInfoHash{$SENSKEYS[$_]}
                  = exists( $SensScale{$ret{$SENSKEYS[$_]}->[$sens]} )
                  ? $SensScale{$ret{$SENSKEYS[$_]}->[$sens]}
                  : $ret{$SENSKEYS[$_]}->[$sens];
            } elsif ( $_ == 4 ) {
                $SensInfoHash{$SENSKEYS[$_]}
                  = exists( $SensStatus{$ret{$SENSKEYS[$_]}->[$sens]} )
                  ? $SensStatus{$ret{$SENSKEYS[$_]}->[$sens]}
                  : $ret{$SENSKEYS[$_]}->[$sens];
            } else {
                $SensInfoHash{$SENSKEYS[$_]} = $ret{$SENSKEYS[$_]}->[$sens];
            }
        }
        $SensInfo{$ret{$SENSKEYS[$#SENSKEYS]}->[$sens]} = \%SensInfoHash;
    }
    return bless \%SensInfo, $class;
}

for ( sensOIDs() ) {
    Cisco::SNMP::_mk_accessors_hash_1( 'sens', $_ );
}

no strict 'refs';

# get_ direct
my @OIDS = sensOIDs();

# -1 because last key (EntityId) isn't an OID; rather, added
for my $o ( 0 .. $#OIDS - 1 ) {
    *{"get_sens" . $OIDS[$o]} = sub {
        my $self = shift;
        my ($val) = @_;

        if ( not defined $val ) { $val = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_sensOID() . '.' . ( $o + 1 ) . '.' . $val] );
        return $r->{_sensOID() . '.' . ( $o + 1 ) . '.' . $val};
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

Cisco::SNMP::Sensor - Sensor Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Sensor;

=head1 DESCRIPTION

The following methods are for Sensor statistics.  These methods
implement the C<CISCO-ENTITY-SENSOR-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::Sensor object

  my $cm = Cisco::SNMP::Sensor->new([OPTIONS]);

Create a new B<Cisco::SNMP::Sensor> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 sensOIDs() - return OID names

  my @sensOIDs = $cm->sensOIDs();

Return list of Sensor MIB object ID names.

=head2 sensor_info() - return sensor statistics info

  my $sensinfo = $cm->sensor_info();

Populate a data structure with sensor information.  If successful,
returns a pointer to an array containing sensor information.

  $sensinfo->[0]->{'Type', 'Scale', 'Precision', ...}
  $sensinfo->[1]->{'Type', 'Scale', 'Precision', ...}
  ...
  $sensinfo->[n]->{'Type', 'Scale', 'Precision', ...}

Allows the following accessors to be called.

=head3 sensType() - return sensor type

  $sensinfo->sensType([#]);

Return the type of the sensor at index '#'.  Defaults to 0.

=head3 sensScale() - return sensor scale

  $sensinfo->sensScale([#]);

Return the scale of the sensor at index '#'.  Defaults to 0.

=head3 sensPrecision() - return sensor precision

  $sensinfo->sensPrecision([#]);

Return the precision of the sensor at index '#'.  Defaults to 0.

=head3 sensValue() - return sensor value

  $sensinfo->sensValue([#]);

Return the value of the sensor at index '#'.  Defaults to 0.

=head3 sensStatus() - return sensor status

  $sensinfo->sensStatus([#]);

Return the status of the sensor at index '#'.  Defaults to 0.

=head3 sensValueTimeStamp() - return sensor value timestamp

  $sensinfo->sensValueTimeStamp([#]);

Return the value timestamp of the sensor at index '#'.  Defaults to 0.

=head3 sensValueUpdateRate() - return sensor value update rate

  $sensinfo->sensValueUpdateRate([#]);

Return the value update rate of the sensor at index '#'.  Defaults to 0.

=head3 sensEntityId() - return sensor entity ID

  $sensinfo->sensEntityId([#]);

Return the entity ID of the sensor at index '#'.  Defaults to 0.  This is a 
derived value, not an actual MIB OID.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::Sensor> object 
directly to access the values directly.

=over 4

=item B<get_sensType> (#)

=item B<get_sensScale> (#)

=item B<get_sensPrecision> (#)

=item B<get_sensValue> (#)

=item B<get_sensStatus> (#)

=item B<get_sensValueTimeStamp> (#)

=item B<get_sensValueUpdateRate> (#)

Get Sensor OIDs where (#) is the OID instance, not the index from 
C<sensor_info>.  If (#) not provided, uses 0.

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
