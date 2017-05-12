#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::Partition;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getVolumeIds {
    my $self = shift;
    return unless ref $self->{_headers};
    return keys %{$self->{_headers}->{_byId}};
}

sub getVolumeNames {
    my $self = shift;
    return unless ref $self->{_headers};
    return keys %{$self->{_headers}->{_byName}};
}

sub getVolumeHeaderById {
    my $self = shift;
    my $id = shift;
    return unless ref $self->{_headers} && ref $self->{_headers}->{_byId};
    return $self->{_headers}->{_byId}->{$id};
}

sub getVolumeHeaderByName {
    my $self = shift;
    my $name = shift;
    return unless ref $self->{_headers} && ref $self->{_headers}->{_byName};
    return $self->{_headers}->{_byName}->{$name};
}

sub getVolumeHeaders {
    my $self = shift;
    return unless ref $self->{_headers} && ref $self->{_headers}->{_byId};
    return values %{$self->{_headers}->{_byId}};
}

sub getVolumeHeader {

    my $self = shift;
    my (%args) = @_;

    if ( exists $args{id} && exists $args{name} ) {
	$self->_Carp("Invalid arguments: both of 'id' or 'name' may not be specified");
	return;
    }

    unless ( exists $args{id} || exists $args{name} )  {
	$self->_Carp("Invalid arguments: at least one of 'id' or 'name' must be specified");
	return;
    }

    if ( exists $args{id} ) {
	return unless ref $self->{_headers} && ref $self->{_headers}->{_byId};
	return $self->{_headers}->{_byId}->{$args{id}};
    }

    if ( exists $args{name} ) {
	return unless ref $self->{_headers} && ref $self->{_headers}->{_byName};
	return $self->{_headers}->{_byName}->{$args{name}};
    }

}

sub _addVolumeHeader {

    my $self = shift;
    my $header = shift;

    unless ( ref $header && $header->isa("AFS::Object::VolumeHeader") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::VolumeHeader object");
    }

    if ( $header->hasAttribute('name') ) {
	$self->{_headers}->{_byName}->{$header->name()} = $header;
    }

    if ( $header->hasAttribute('id') ) {
	$self->{_headers}->{_byId}->{$header->id()} = $header;
    } else {
	$self->_Croak("Volume header has no id attribute!!\n" .
		      Data::Dumper->Dump([$header],['header']));
    }

    return 1;

}

1;
