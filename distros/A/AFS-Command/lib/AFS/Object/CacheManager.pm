#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::CacheManager;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getPathNames {
    my $self = shift;
    return unless ref $self->{_pathnames};
    return keys %{$self->{_pathnames}};
}

sub getPaths {
    my $self = shift;
    return unless ref $self->{_pathnames};
    return values %{$self->{_pathnames}};
}

sub getPath {
    my $self = shift;
    my $path = shift;
    return unless ref $self->{_pathnames};
    return $self->{_pathnames}->{$path};
}

sub _addPath {
    my $self = shift;
    my $path = shift;
    unless ( ref $path && $path->isa("AFS::Object::Path") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::Path object");
    }
    return $self->{_pathnames}->{$path->path()} = $path;
}

sub getCellNames {
    my $self = shift;
    return unless ref $self->{_cells};
    return keys %{$self->{_cells}};
}

sub getCells {
    my $self = shift;
    return unless ref $self->{_cells};
    return values %{$self->{_cells}};
}

sub getCell {
    my $self = shift;
    my $cell = shift;
    return unless ref $self->{_cells};
    return $self->{_cells}->{$cell};
}

sub _addCell {
    my $self = shift;
    my $cell = shift;
    unless ( ref $cell && $cell->isa("AFS::Object::Cell") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::Cell object");
    }
    return $self->{_cells}->{$cell->cell()} = $cell;
}

sub getServerNames {
    my $self = shift;
    return unless ref $self->{_servers};
    return keys %{$self->{_servers}};
}

sub getServers {
    my $self = shift;
    return unless ref $self->{_servers};
    return values %{$self->{_servers}};
}

sub getServer {
    my $self = shift;
    my $server = shift;
    return unless ref $self->{_servers};
    return $self->{_servers}->{$server};
}

sub _addServer {
    my $self = shift;
    my $server = shift;
    unless ( ref $server && $server->isa("AFS::Object::Server") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::Server object");
    }
    return $self->{_servers}->{$server->server()} = $server;
}

1;
