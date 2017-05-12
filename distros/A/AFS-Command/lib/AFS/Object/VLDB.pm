#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::VLDB;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getVolumeNames {
    my $self = shift;
    return unless ref $self->{_names};
    return keys %{$self->{_names}};
}

sub getVolumeIds {
    my $self = shift;
    return unless ref $self->{_ids};
    return keys %{$self->{_ids}};
}

sub getVLDBEntry {

    my $self = shift;

    my %args = ();

    if ( $#_ == 0 ) {
	if ( $^W ) {
	    $self->_Carp("WARNING: getVLDBEntry(\$name) usage is deprecated\n" .
			 "Use getVLDBENtryByName(\$name), or getVLDBERntry( name => \$name )\n");
	}
	$args{name} = shift;
    } else {
	%args = @_;
    }

    if ( exists $args{id} && exists $args{name} ) {
	$self->_Carp("Invalid arguments: both of 'id' or 'name' may not be specified");
	return;
    }

    unless ( exists $args{id} || exists $args{name} )  {
	$self->_Carp("Invalid arguments: at least one of 'id' or 'name' must be specified");
	return;
    }

    if ( exists $args{id} ) {
	return unless ref $self->{_ids};
	return $self->{_ids}->{$args{id}};
    }

    if ( exists $args{name} ) {
	return unless ref $self->{_names};
	return $self->{_names}->{$args{name}};
    }

}

sub getVLDBEntryByName {
    my $self = shift;
    my $name = shift;
    return unless ref $self->{_names};
    return $self->{_names}->{$name};
}

sub getVLDBEntryById {
    my $self = shift;
    my $id = shift;
    return unless ref $self->{_ids};
    return $self->{_ids}->{$id};
}

sub getVLDBEntries {
    my $self = shift;
    return unless ref $self->{_names};
    return values %{$self->{_names}};
}

sub _addVLDBEntry {

    my $self = shift;
    my $entry = shift;

    unless ( ref $entry && $entry->isa("AFS::Object::VLDBEntry") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::VLDBEntry object");
    }

    foreach my $id ( $entry->rwrite(), $entry->ronly(),
		     $entry->backup(), $entry->rclone() ) {
	next unless $id; # Some, in fact most, of those won't exist
	$self->{_ids}->{$id} = $entry;
    }

    return $self->{_names}->{$entry->name()} = $entry;

}

1;
