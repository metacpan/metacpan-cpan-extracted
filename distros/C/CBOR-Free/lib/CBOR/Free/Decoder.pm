package CBOR::Free::Decoder;

=encoding utf8

=head1 NAME

CBOR::Free::Decoder

=head1 SYNOPSIS

    my $decoder = CBOR::Free::Decoder->new()->set_tag_handlers(
        2 => sub { DateTime->from_epoch( epoch => shift() ) },
    );

    # Enable shared/circular references:
    $decoder->preserve_references();

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

sub new { bless {} }    # TODO: implement in XS, and store a context.

#----------------------------------------------------------------------

=head2 $data = I<OBJ>->decode( $CBOR )

Same as L<CBOR::Free>’s static function of the same name but applies
any tag handlers configured in C<set_tag_handlers()>.

As in L<CBOR::Free>, any unrecognized tags prompt a warning but are
otherwise ignored.

=cut

#----------------------------------------------------------------------

=head2 $enabled_yn = I<OBJ>->preserve_references( [$ENABLE] )

Enables/disables recognition of CBOR’s shared references. (If no
argument is given, shared references wil be enabled.)

B<HANDLE WITH CARE.> This option can cause CBOR::Free to create circular
references, which can cause memory leaks if not handled properly.

=cut

sub preserve_references {
    return $_[0]{'_preserve_references'} = (@_ > 1 ? !!$_[1] : 1);
}

#----------------------------------------------------------------------

=head2 I<OBJ>->set_tag_handlers( %TAG_CALLBACK )

Takes a list of key/value pairs where each key is a tag (i.e., number)
and each value is a coderef that CBOR::Free will run when that tag is
seen during a decode operation. The coderef will receive the tagged value,
and its (scalar) return will be inserted into the decoded data structure.

To unset a tag handler, assign undef to it.

This returns the I<OBJ>.

B<NOTE:> Handlers assigned here will only fire if CBOR::Free itself
doesn’t decode the tag. For example, a handler for the “indirection” tag
here will be ignored.

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
