# Connector::Builtin::Null
package Connector::Builtin::Null;

use strict;
use warnings;
use English;

use Moose;
extends 'Connector::Builtin';

has '+LOCATION' => ( required => 0 );

sub get {
    my $self = shift;
    return undef;
}

sub get_list {
    my $self = shift;
    return ();
}

sub get_size {
    my $self = shift;
    return 0;
}

sub get_keys {
    my $self = shift;
    return ();
}

sub get_hash {
    my $self = shift;
    return undef;
}

sub set {
    my $self = shift;
    return 1;
}

sub exists {
    my $self = shift;
    return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 Name

Connector::Builtin::Null

=head1 Description

This is mainly useful to replace active connectors in test setups.

Handles each request as access to a non-existing items.
Set requests return boolean true, input is discarded.
