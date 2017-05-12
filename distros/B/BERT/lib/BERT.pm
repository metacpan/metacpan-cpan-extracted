package BERT;
use strict;
use warnings;

use 5.008;

use base 'Exporter';
our @EXPORT = qw(encode_bert decode_bert);

our $VERSION = 0.06;

use BERT::Decoder;
use BERT::Encoder;

sub encode_bert {
    my $value = shift;
    my $encoder = BERT::Encoder->new;
    return $encoder->encode($value);
}

sub decode_bert {
    my $bert = shift;
    my $decoder = BERT::Decoder->new;
    return $decoder->decode($bert);
}

1;

__END__

=head1 NAME

BERT - BERT serializer/deserializer

=head1 SYNOPSIS

  use BERT;

  my $bert = encode_bert([ 1, 'foo', [ 2, [ 3, 4 ] ], 5 ]);
  my $data = decode_bert($bert);

=head1 DESCRIPTION

This module provides a thin wrapper around L<BERT::Encoder> and L<BERT::Decoder>, 
which converts Perl data structures to BERT format and vice versa, respectively.

See the BERT specification at L<http://bert-rpc.org/>.

=head1 FUNCTIONS

=over 4

=item $bert = encode_bert($data)

Returns the BERT representation for the given Perl data structure. Croaks on error.

=item $data = decode_bert($bert)

Returns the Perl data structure for the given BERT binary. Croaks on error.

=back

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<BERT::Encoder> L<BERT::Decoder>

=cut
