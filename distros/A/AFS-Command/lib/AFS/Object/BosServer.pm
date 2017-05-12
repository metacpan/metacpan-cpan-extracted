#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::BosServer;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getInstanceNames {
    my $self = shift;
    return unless ref $self->{_instances};
    return keys %{$self->{_instances}};
}

sub getInstance {
    my $self = shift;
    my $name = shift;
    return unless ref $self->{_instances};
    return $self->{_instances}->{$name};
}

sub getInstances {
    my $self = shift;
    return unless ref $self->{_instances};
    return values %{$self->{_instances}};
}

sub _addInstance {
    my $self = shift;
    my $instance = shift;
    unless ( ref $instance && $instance->isa("AFS::Object::Instance") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::Instance object");
    }
    return $self->{_instances}->{$instance->instance()} = $instance;
}

sub getFileNames {
    my $self = shift;
    return unless ref $self->{_files};
    return keys %{$self->{_files}};
}

sub getFile {
    my $self = shift;
    my $filename = shift;
    return unless ref $self->{_files};
    return $self->{_files}->{$filename};
}

sub getFiles {
    my $self = shift;
    return unless ref $self->{_files};
    return values %{$self->{_files}};
}

sub _addFile {
    my $self = shift;
    my $file = shift;
    unless ( ref $file && $file->isa("AFS::Object") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object object");
    }
    return $self->{_files}->{$file->file()} = $file;
}

sub getKeyIndexes {
    my $self = shift;
    return unless ref $self->{_keys};
    return keys %{$self->{_keys}};
}

sub getKey {
    my $self = shift;
    my $index = shift;
    return unless ref $self->{_keys};
    return $self->{_keys}->{$index};
}

sub getKeys {
    my $self = shift;
    return unless ref $self->{_keys};
    return values %{$self->{_keys}};
}

sub _addKey {
    my $self = shift;
    my $key = shift;
    unless ( ref $key && $key->isa("AFS::Object") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object object");
    }
    return $self->{_keys}->{$key->index()} = $key;
}

1;

