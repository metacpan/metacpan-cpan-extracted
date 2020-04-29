package CBOR::Free::SequenceDecoder;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

CBOR::Free::SequenceDecoder

=head1 SYNOPSIS

    my $decoder = CBOR::Free::SequenceDecoder->new();

    if ( my $got_sr = $decoder->give( $some_cbor ) ) {

        # Do something with your decoded CBOR.
    }

    while (my $got_sr = $decoder->get()) {
        # Do something with your decoded CBOR.
    }

=head1 DESCRIPTION

This module implements a parser for CBOR Sequences
(L<RFC 8742|https://tools.ietf.org/html/rfc8742>).

=cut

#----------------------------------------------------------------------

use parent qw( CBOR::Free::Decoder::Base );

use CBOR::Free;

#----------------------------------------------------------------------

=head1 METHODS

This module implements the following methods in common
with L<CBOR::Free::Decoder>:

=over

=item * C<new()>

=item * C<preserve_references()>

=item * C<naive_utf8()>

=item * C<string_decode_cbor()>

=item * C<string_decode_never()>

=item * C<string_decode_always()>

=item * C<set_tag_handlers()>

=back

Additionally, the following exist:

=head2 $got_sr = I<CLASS>->give( $CBOR );

Adds some bytes ($CBOR) to the decoder’s internal CBOR buffer.
Returns either:

=over

=item * a B<scalar reference> to the (parsed) first CBOR document in the
internal buffer

=item * undef, if there is no such document

=back

Note that if your decoded CBOR document’s root element is already a reference
(e.g., an array or hash reference), then the return value is a reference
B<to> that reference. So, for example, if you expect all documents in your
stream to be array references, you could do:

    if ( my $got_sr = $decoder->give( $some_cbor ) ) {
        my @decoded_array = @{ $$got_sr };

        # …
    }

=head2 $got_sr = I<CLASS>->get();

Like C<give()> but doesn’t append onto the internal CBOR buffer.

=cut

1;
