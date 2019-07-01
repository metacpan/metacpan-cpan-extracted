package CBOR::Free::Decoder;

=head1 NAME

CBOR::Free::Decoder

=head1 SYNOPSIS

    my $decoder = CBOR::Free::Decoder->new()->set_tag_handlers(
        2 => sub { DateTime->from_epoch( epoch => shift() ) },
    );

=head1 DESCRIPTION

This class provides an object-oriented interface to L<CBOR::Free>’s
decoder. This interface allows interpretation of tagged values.

=cut

#----------------------------------------------------------------------

use CBOR::Free ();

#----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new()

Creates a new CBOR decoder object.

=cut

sub new { bless {} }

#----------------------------------------------------------------------

=head2 $data = I<OBJ>->decode( $CBOR )

Same as L<CBOR::Free>’s static function of the same name but applies
any tag handlers configured in C<set_tag_handlers()>.

As in L<CBOR::Free>, any unrecognized tags prompt a warning but are
otherwise ignored.

=cut

#----------------------------------------------------------------------

=head2 I<OBJ>->set_tag_handlers( %TAG_CALLBACK )

Takes a list of key/value pairs where each key is a tag (i.e., number)
and each value is a coderef that CBOR::Free will run when that tag is
seen during a decode operation. The coderef will receive the tagged value,
and its (scalar) return will be inserted into the decoded data structure.

To unset a tag handler, assign undef to it.

This returns the I<OBJ>.

=cut

use constant _TAG_PACK_TMPL => eval { pack 'Q' } ? 'Q' : 'L';

sub set_tag_handlers {
    my ($self, @tag_cb) = @_;

    while (my ($tag, $cb) = splice @tag_cb, 0, 2) {
        $self->{'_tag_decode_callback'}{ pack( _TAG_PACK_TMPL(), $tag ) } = $cb;
    }

    return $self;
}

1;
