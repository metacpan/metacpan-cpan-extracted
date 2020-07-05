# Connector::Builtin::Memory
#
# Proxy class for reading YAML configuration
#
# Written by Scott Hardin, Martin Bartosch and Oliver Welter
# for the OpenXPKI project 2012
#
# THIS IS NOT WORKING IN A FORKING ENVIRONMENT!


package Connector::Builtin::Memory;

use strict;
use warnings;
use English;
use Data::Dumper;

use Moose;
extends 'Connector::Builtin';

has '+LOCATION' => ( required => 0 );

sub _build_config {
    my $self = shift;
    $self->_config( {} );
}

sub _get_node {

    my $self = shift;
    my @path = $self->_build_path_with_prefix( shift );

    $self->log()->trace('get node for path'. Dumper \@path);

    my $ptr = $self->_config();

    # Top Level Node requested
    if (!@path) {
        return $ptr;
    }

    while ( scalar @path > 1 ) {
        my $entry = shift @path;
        if ( exists $ptr->{$entry} ) {
            if ( ref $ptr->{$entry} eq 'HASH' ) {
                $ptr = $ptr->{$entry};
            }
            else {
                return $self->_node_not_exists( ref $ptr->{$entry} );
            }
        } else {
            return $self->_node_not_exists($entry);
        }
    }

    return $ptr->{ shift @path };

}

sub get {

    my $self = shift;
    my $value = $self->_get_node( shift );

    return $self->_node_not_exists() unless (defined $value);

    if (ref $value ne '') {
        die "requested value is not a scalar";
    }

    return $value;

}

sub get_size {

    my $self = shift;
    my $node = $self->_get_node( shift );

    return 0 unless(defined $node);

    if ( ref $node ne 'ARRAY' ) {
        die "requested value is not a list"
    }

    return scalar @{$node};
}

sub get_list {

    my $self = shift;
    my $path = shift;

    my $node = $self->_get_node( $path );

    return $self->_node_not_exists( $path ) unless(defined $node);

    if ( ref $node ne 'ARRAY' ) {
        die "requested value is not a list"
    }

    return @{$node};
}

sub get_keys {

    my $self = shift;
    my $path = shift;

    my $node = $self->_get_node( $path );

    return @{[]} unless(defined $node);

    if ( ref $node ne 'HASH' ) {
        die "requested value is not a hash"
    }

    return keys %{$node};
}

sub get_hash {

    my $self = shift;
    my $path = shift;

    my $node = $self->_get_node( $path );

    return $self->_node_not_exists( $path ) unless(defined $node);

    if ( ref $node ne 'HASH' ) {
        die "requested value is not a hash"
    }

    return { %$node };
}

sub get_meta {

    my $self = shift;

    my $node = $self->_get_node( shift );

    $self->log()->trace('get_node returned '. Dumper $node);

    if (!defined $node) {
        # die_on_undef already handled by get_node
        return;
    }

    my $meta = {};

    if (ref $node eq '') {
        $meta = {TYPE  => "scalar", VALUE => $node };
    } elsif (ref $node eq "SCALAR") {
        $meta = {TYPE  => "reference", VALUE => $$node };
    } elsif (ref $node eq "ARRAY") {
        $meta = {TYPE  => "list", VALUE => $node };
    } elsif (ref $node eq "HASH") {
        my @keys = keys(%{$node});
        $meta = {TYPE  => "hash", VALUE => \@keys };
    } elsif (blessed($node) && $node->isa('Connector')) {
        $meta = {TYPE  => "connector", VALUE => $node };
    } else {
        die "Unsupported node type: " . ref $node;
    }
    return $meta;
}

sub exists {

    my $self = shift;

    my $value = 0;
    eval {
        $value = defined $self->_get_node( shift );
    };
    return $value;

}

sub set {

    my $self = shift;
    my @path = $self->_build_path_with_prefix( shift );

    my $value = shift;

    my $ptr = $self->_config();

    while (scalar @path > 1) {
        my $entry = shift @path;
        if (!exists $ptr->{$entry}) {
            $ptr->{$entry} = {};
        } elsif (ref $ptr->{$entry} ne "HASH") {
            confess('Try to step over a value node at ' . $entry);
        }
        $ptr = $ptr->{$entry};
    }

    my $entry = shift @path;

    if (!defined $value) {
        delete $ptr->{$entry};
        return;
    }

    if (exists $ptr->{$entry}) {
        if (ref $ptr->{$entry} ne ref $value) {
            confess('Try to override data type at node ' . $entry);
        }
    }
    $ptr->{$entry} = $value;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Builtin::Memory

=head 1 Description

A connector implementation to allow memory based caching
