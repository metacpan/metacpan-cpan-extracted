# Connector::Builtin::Env
#
# Read values from the environment
#
# Written by Oliver Welter for the OpenXPKI project 2014
#
package Connector::Builtin::Env;

use strict;
use warnings;
use English;
use File::Spec;
use Data::Dumper;

use Moose;
extends 'Connector::Builtin';

has '+LOCATION' => ( required => 0 );

has prefix => (
    is  => 'rw',
    isa => 'Str',
    default => ''
);

sub get {

    my $self = shift;
    my $key = shift;
    my $val = $self->_get_node( $key );

    if (!defined $val) {
        return $self->_node_not_exists( $key  );
    }

    return $val;

}

sub get_meta {
    my $self = shift;
    return { TYPE  => "scalar" };
}

sub exists {

    my $self = shift;
    my $val = $self->_get_node( shift );
    return defined $val;

}

sub _get_node {

    my $self = shift;

    my $prefix = $self->prefix();

    my $key = shift;
    # We expect only a scalar key, so this is a fast and valid conversion
    $key = $key->[0] if (ref $key eq 'ARRAY');

    return $ENV{$prefix.$key};

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Builtin::Env

=head 1 Description

Return the contents of a environment value.
The value of LOCATION is not used.

=head2 Configuration

Connector::Builtin::Env->new({
    'LOCATION' => 'Not Used'
    'prefix' => 'optional prefix to be prepended to all keys',
});

