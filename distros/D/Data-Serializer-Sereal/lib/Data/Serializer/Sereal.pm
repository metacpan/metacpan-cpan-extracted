package Data::Serializer::Sereal;

use strict;
use warnings;
use base qw(Data::Serializer);
use Sereal::Encoder qw(sereal_encode_with_object);
use Sereal::Decoder qw(sereal_decode_with_object);

=head1 NAME

Data::Serializer::Sereal - Creates bridge between Data::Serializer and Sereal

=head1 VERSION

Version 1.05

=cut

our $VERSION = '1.05';

our $ENCODER;
our $DECODER;


=head1 SYNOPSIS

Creates bridge between Data::Serializer and Sereal

=head1 SUBROUTINES/METHODS

=head2 serialize

serialize object/data

=cut

sub serialize {
    my ($self, $object) = @_;
    return sereal_encode_with_object($self->encoder, $object);
}

=head2 deserialize

deserialize object/data

=cut

sub deserialize {
    my ($self) = @_;
    my $object;
    sereal_decode_with_object($self->decoder, $_[1], $object);
    return $object;
}

=head2 decoder

gets the decoder from options or uses the default decoder

=cut

sub decoder {
    my ($self) = @_;
    my $decoder = $self->{options}{decoder};
    return $decoder if ref($decoder) eq 'Sereal::Decoder';
    return $DECODER ||= Sereal::Decoder->new();
}

=head2 encoder

gets the encoder from options or uses the default encoder

=cut

sub encoder {
    my ($self) = @_;
    my $encoder = $self->{options}{encoder};
    return $encoder if ref($encoder) eq 'Sereal::Encoder';
    return $ENCODER ||= Sereal::Encoder->new();
}

=head2

Recreates global ENCODER/DECODER after thread is created

=cut

sub CLONE {
    $ENCODER = undef;
    $DECODER = undef;
}

=head1 AUTHOR

James Rouzier, C<< <rouzier at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-serializer-sereal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Serializer-Sereal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Serializer::Sereal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Serializer-Sereal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Serializer-Sereal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Serializer-Sereal>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Serializer-Sereal/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2014 James Rouzier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Serializer::Sereal
