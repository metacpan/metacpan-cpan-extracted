# Connector::Builtin::Static
#
# Simple connector returning a static value for all requests
#
package Connector::Builtin::Static;

use strict;
use warnings;
use English;

use Moose;
extends 'Connector::Builtin';

sub get {
    my $self = shift;
    my $arg = shift;

    return $self->{LOCATION};
}

sub get_meta {

    my $self = shift;
    return { TYPE  => "scalar", VALUE => $self->{LOCATION} };
}

sub exists {

    my $self = shift;
    return 1;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Builtin::Simple

=head 1 Description

Return a static value regardless of the requested key.
Set the value using the "LOCATION" parameter. Supports only
scalar values using the get/get_meta call.
