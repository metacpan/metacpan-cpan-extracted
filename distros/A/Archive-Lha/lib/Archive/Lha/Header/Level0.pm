package Archive::Lha::Header::Level0;

use strict;
use warnings;
use Carp;
use Archive::Lha::Constants;
use Archive::Lha::Header::Base;
use Archive::Lha::Header::Utils;

sub new {
  my ($class, $stream) = @_;

  my $start = $stream->tell;
  my $size  = ord($stream->read(1)) + 2;

  croak "Header is broken: size is too small: $size" if $size < 24;

  $stream->seek($start);
  my $buf = $stream->read($size);

  my $checksum  = ord(substr($buf, 1, 1));
  my $checksum1 = defined &Archive::Lha::Header::Utils::checksum
    ? Archive::Lha::Header::Utils::checksum($buf, 2)
    : do { my $s = 0; $s += $_ for unpack 'C*', substr($buf, 2); $s & CHAR_MAX };
  croak "Header is broken: pos:$start checksum $checksum/$checksum1"
    unless $checksum == $checksum1;

  my %header;
  $header{header_top}      = $start;
  $header{header_size}     = $size;
  $header{header_checksum} = $checksum;
  $header{method}          = substr($buf, 3, 3);
  $header{encoded_size}    = unpack 'V', substr($buf,  7, 4);
  $header{original_size}   = unpack 'V', substr($buf, 11, 4);
  $header{timestamp}       = unpack 'V', substr($buf, 15, 4);

  my $pathname_length = ord(substr($buf, 21, 1));
  $header{pathname}   = substr($buf, 22, $pathname_length);
  if ($header{pathname} =~ s/\0(.+)//s) {
    $header{comment} = $1;
  }
  $header{crc16} = unpack 'v', substr($buf, 22 + $pathname_length, 2);

  my $ext_from = 24 + $pathname_length;
  if ($ext_from < $size) {
    my (undef, $ext) = _extended_header_buf($buf, $ext_from, $size - $ext_from);
    %header = (%header, %{ $ext }) if %{ $ext };
  }

  $header{data_top}    = $start + $size;
  $header{next_header} = $header{data_top} + $header{encoded_size};

  bless \%header, $class;
}

1;

__END__

=head1 NAME

Archive::Lha::Header::Level0

=head1 DESCRIPTION

You usually don't need to use this directly. See L<Archive::Lha::Header> for examples.

This parses Level 0 headers found mainly in the oldest archives created in the MS-DOS era.

=head1 METHODS

=head2 new

parses a stream and creates an object.

=head1 SEE ALSO

L<Archive::Lha::Header::Base>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
