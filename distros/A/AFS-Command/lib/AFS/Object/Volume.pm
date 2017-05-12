#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::Volume;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getVolumeHeaders {
    my $self = shift;
    return unless ref $self->{_headers};
    return @{$self->{_headers}};
}

sub _addVolumeHeader {
    my $self = shift;
    my $header = shift;
    unless ( ref $header && $header->isa("AFS::Object::VolumeHeader") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::VolumeHeader object");
    }
    return push( @{$self->{_headers}}, $header );
}

sub getVLDBEntry {
    my $self = shift;
    return $self->{_vldbentry};
}

sub _addVLDBEntry {
    my $self = shift;
    my $entry = shift;
    unless ( ref $entry && $entry->isa("AFS::Object::VLDBEntry") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::VLDBEntry object");
    }
    return $self->{_vldbentry} = $entry;
}

1;

