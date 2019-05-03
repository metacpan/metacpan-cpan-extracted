package CBOR::Free::Tagged;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

CBOR::Free::Tagged

=head1 SYNOPSIS

    my $tagged = CBOR::Free::Tagged->new( 1, '2019-05-01T01:02:03Z' );

=head1 DESCRIPTION

This class represents tagged objects for L<CBOR::Free>. You might as well
invoke it via C<CBOR::Free::tagged()> rather than instantiating this class
directly, though.

=head1 METHODS

=head2 $obj = I<CLASS>->new( $TAG_NUMBER, $VALUE )

$TAG_NUMBER is the CBOR tag number to apply on the given $VALUE.

Returns a class instance.

=cut

sub new {
    return bless \@_, shift;
}

1;
