package CBOR::Free::Decoder::Base;

use strict;
use warnings;

sub set_tag_handlers {
    my ($self, @tag_kv) = @_;

    die "Uneven tag handlers list given!" if @tag_kv % 2;

    my @tag_kv_copy = @tag_kv;

    while ( my ($tag, $cr) = splice @tag_kv ) {
        die "Invalid tag: $tag" if $tag !~ m<\A[0-9]+\z>;
        die "Invalid tag $tag handler: $cr" if defined($cr) && !UNIVERSAL::isa($cr, 'CODE');
    }

    $self->_set_tag_handlers_backend(@tag_kv_copy);

    return $self;
}

1;
