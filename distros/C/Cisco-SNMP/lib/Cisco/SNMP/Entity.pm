package Cisco::SNMP::Entity;

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

sub _entityOID {
    return '1.3.6.1.2.1.47.1.1.1.1'
}

sub entityOIDs {
    return qw(Descr VendorType ContainedIn Class ParentRelPos Name HardwareRev FirmwareRev SoftwareRev SerialNum MfgName ModelName Alias AssetID IsFRU)
}

sub entity_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my @ENTITYKEYS = entityOIDs();
    my %ret;
    for my $oid (0..$#ENTITYKEYS) {
        $ret{$ENTITYKEYS[$oid]} = Cisco::SNMP::_snmpwalk($session, _entityOID() . '.' . ($oid+2));
        if (!defined $ret{$ENTITYKEYS[$oid]}) {
            $Cisco::SNMP::LASTERROR = "Cannot get entity `$ENTITYKEYS[$oid]' info";
            return undef
        }
    }

    my @Entity;
    for my $unit (0..$#{$ret{$ENTITYKEYS[5]}}) {
        my %EntityHash;
        for (0..$#ENTITYKEYS) {
            $EntityHash{$ENTITYKEYS[$_]} = $ret{$ENTITYKEYS[$_]}->[$unit]
        }
        push @Entity, \%EntityHash
    }
    return bless \@Entity, $class
}

for (entityOIDs()) {
    Cisco::SNMP::_mk_accessors_array_1('entity', $_)
}

no strict 'refs';
# get_ direct
my @OIDS = entityOIDs();
for my $o (0..$#OIDS) {
    *{"get_entity" . $OIDS[$o]} = sub {
        my $self  = shift;
        my ($val) = @_;

        if (!defined $val) { $val = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_entityOID() . '.' . ($o+2) . '.' . $val]
        );
        return $r->{_entityOID() . '.' . ($o+2) . '.' . $val}
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

Cisco::SNMP::Entity - Entity Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Entity;

=head1 DESCRIPTION

The following methods implement the Entity MIB defined in C<ENTITY-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::Entity object

  my $cm = Cisco::SNMP::Entity->new([OPTIONS]);

Create a new B<Cisco::SNMP::Entity> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 entityOIDs() - return OID names

  my @entityOIDs = $cm->entityOIDs();

Return list of Entity MIB object ID names.

=head2 entity_info() - return entity info

  my $entity = $cm->entity_info();

Populate a data structure with entity information.  If successful,
returns a pointer to an array containing entity information.

  $entity->[0]->{'Descr', 'VendorType', ...}
  $entity->[1]->{'Descr', 'VendorType', ...}
  ...
  $entity->[n]->{'Descr', 'VendorType', ...}

Allows the following accessors to be called.

=head3 entityDescr - return entity description

  $entity->entityDescr([#]);

Return the description of the entity at index '#'.  Defaults to 0.

=head3 entityVendorType - return entity vendor type

  $entity->entityVendorType([#]);

Return the vendor type of the entity at index '#'.  Defaults to 0.

=head3 entityContainedIn - return entity ContainedIn

  $entity->entityContainedIn([#]);

Return the ContainedIn of the entity at index '#'.  Defaults to 0.

=head3 entityClass - return entity class

  $entity->entityClass([#]);

Return the class of the entity at index '#'.  Defaults to 0.

=head3 entityParentRelPos - return entity ParentRelPos

  $entity->entityParentRelPos([#]);

Return the ParentRelPos of the entity at index '#'.  Defaults to 0.

=head3 entityName - return entity name

  $entity->entityName([#]);

Return the name of the entity at index '#'.  Defaults to 0.

=head3 entityHardwareRev - return entity hardware revision

  $entity->entityHardwareRev([#]);

Return the hardware revision of the entity at index '#'.  Defaults to 0.

=head3 entityFirmwareRev - return entity firmware revision

  $entity->entityFirmwareRev([#]);

Return the firmware revision of the entity at index '#'.  Defaults to 0.

=head3 entitySoftwareRev - return entity software revision

  $entity->entitySoftwareRev([#]);

Return the software revision of the entity at index '#'.  Defaults to 0.

=head3 entitySerialNum - return entity serial number

  $entity->entitySerialNum([#]);

Return the serial number of the entity at index '#'.  Defaults to 0.

=head3 entityMfgName - return entity manufacturer name

  $entity->entityMfgName([#]);

Return the manufacturer name of the entity at index '#'.  Defaults to 0.

=head3 entityModelName - return entity model name

  $entity->entityModelName([#]);

Return the model name of the entity at index '#'.  Defaults to 0.

=head3 entityAlias - return entity alias

  $entity->entityAlias([#]);

Return the alias of the entity at index '#'.  Defaults to 0.

=head3 entityAssetID - return entity asset ID

  $entity->entityAssetID([#]);

Return the asset ID of the entity at index '#'.  Defaults to 0.

=head3 entityIsFRU - return entity IsFRU

  $entity->entityIsFRU([#]);

Return the IsFRU of the entity at index '#'.  Defaults to 0.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::Entity> object 
directly to access the values directly.

=over 4

=item B<get_entityDescr> (#)

=item B<get_entityVendorType> (#)

=item B<get_entityContainedIn> (#)

=item B<get_entityClass> (#)

=item B<get_entityParentRelPos> (#)

=item B<get_entityName> (#)

=item B<get_entityHardwareRev> (#)

=item B<get_entityFirmwareRev> (#)

=item B<get_entitySoftwareRev> (#)

=item B<get_entitySerialNum> (#)

=item B<get_entityMfgName> (#)

=item B<get_entityModelName> (#)

=item B<get_entityAlias> (#)

=item B<get_entityAssetID> (#)

=item B<get_entityIsFRU> (#)

Get Entity OIDs where (#) is the OID instance, not the index from 
C<entity_info>.  If (#) not provided, uses 0.

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
