use strict;
use warnings;
package Dancer::Serializer::UUEncode;
BEGIN {
  $Dancer::Serializer::UUEncode::VERSION = '0.02';
}
# ABSTRACT: UU Encoding serializer for Dancer

use Carp;
use base 'Dancer::Serializer::Abstract';

sub init {
    my ($self) = @_;
    $self->loaded;
}

sub loaded {
    require Storable;
    Storable->import( qw/ nfreeze thaw / );
}

sub serialize {
    my ( $self, $entity ) = @_;

    return pack( 'u', nfreeze($entity) );
}

sub deserialize {
    my ( $self, $content ) = @_;
    my $data = thaw( unpack( 'u', $content ) );

    defined $data or croak "Couldn't thaw unpacked content '$content'";

    return $data;
}

sub content_type {'text/uuencode'}

# helpers
sub from_uuencode {
    my ($uuencode) = @_;
    my $s = Dancer::Serializer::UUEncode->new;

    return $s->deserialize($uuencode);
}

sub to_uuencode {
    my ($data) = @_;
    my $s = Dancer::Serializer::UUEncode->new;

    return $s->serialize($data);
}

1;



=pod

=head1 NAME

Dancer::Serializer::UUEncode - UU Encoding serializer for Dancer

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # in your Dancer app:
    setting serializer => 'UUEncode';

    # or in your Dancer config file:
    serializer: 'UUEncode'

=head1 DESCRIPTION

This serializer serializes your data structure to UU Encoding. Since UU Encoding
is just encoding and not a serialization format, it first freezes it using
L<Storable> and only then serializes it.

It uses L<Storable>'s C<nfreeze> and C<thaw> functions.

=head1 SUBROUTINES/METHODS

=head2 init

An initializer that is called automatically by Dancer.

Runs C<loaded>.

=head2 loaded

Lazily loads Storable and imports the appropriate functions.

=head2 serialize

Serializes a given data to UU encoding after freezing it with L<Storable>.

=head2 deserialize

Deserializes a given data from UU encoding after thawing it with L<Storable>.

=head2 from_uuencode

Helper function to create a new L<Dancer::Serializer::UUEncode> object and run
C<serialize>.

=head2 to_uuencode

Helper function to create a new L<Dancer::Serializer::UUEncode> object and run
C<deserialize>.

=head2 content_type

Returns the content type of UU encode which is B<text/uuencode>.

=head1 SEE ALSO

The Dancer Advent Calendar 2010.

=head1 AUTHOR

  Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

