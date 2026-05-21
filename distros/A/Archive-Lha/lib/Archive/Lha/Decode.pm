package Archive::Lha::Decode;

use strict;
use warnings;
use Carp;

sub new {
  my ($class, %options) = @_;

  croak "Header is missing" unless defined $options{header};

  my $method = uc $options{header}->method;

  my $package = 'Archive::Lha::Decode::'.$method;

  eval "require $package;";
  croak "Can't load decoder: $@" if $@;

  return $package->new( %options );
}

1;

__END__

=head1 NAME

Archive::Lha::Decode

=head1 SYNOPSIS

  # don't forget :raw, or eol might be converted implicitly
  open my $fh, '>:raw', $header->pathname;
  binmode $fh;
  $stream->seek( $header->data_top );
  my $decoder = Archive::Lha::Decode->new(
    header => $header,
    read   => sub { $stream->read(@_) },
    write  => sub { print $fh @_ },
  )
  my $crc16 = $decoder->decode;
  croak "crc mismatch" if $crc16 != $header->crc16;

=head1 DESCRIPTION

This is used to decode/extract an archived file from the stream. Actually this ::Decode class is a factory and decoding is done by a delegated class according to the header's "method" property.

All of the ::Decode subclasses require read/write callbacks. Read callback should take a byte length as an argument, and return the bytes of the length from a file or a string. Write callback should take a part of the decoded (probably binary) string as an argument, and the rest is up to you. You may want to write it down in a file as shown above, or maybe append it to a string to store in a database after finished. You may want to encode it first, or throw it away if the string contains unprintable binary. You may want to use a temporary file. You may want to update a progress indicator. Do whatever you want.

=head1 METHODS

=head2 new

takes an Archive::Lha::Header object, and read/write callbacks and creates an appropriate object.

=head2 decode

does the decoding stuff and returns CRC-16 of the decoded string. The decoded string itself is passed to the write callback while decoding (step by step).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
