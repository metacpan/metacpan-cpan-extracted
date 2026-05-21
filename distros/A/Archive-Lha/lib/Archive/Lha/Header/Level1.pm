package Archive::Lha::Header::Level1;

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

  croak "Header is broken: size is too small: $size" if $size < 27;

  $stream->seek($start);
  my $buf = $stream->read($size);

  my $checksum  = ord(substr($buf, 1, 1));
  my $checksum1 = defined &Archive::Lha::Header::Utils::checksum
    ? Archive::Lha::Header::Utils::checksum($buf, 2)
    : do { my $s = 0; $s += $_ for unpack 'C*', substr($buf, 2); $s & CHAR_MAX };
  croak "Header is broken: checksum $checksum/$checksum1"
    unless $checksum == $checksum1;

  my %header;
  $header{header_top}      = $start;
  $header{header_size}     = $size;
  $header{header_checksum} = $checksum;
  $header{method}          = substr($buf, 3, 3);
  $header{skip_size}       = unpack 'V', substr($buf,  7, 4);
  $header{original_size}   = unpack 'V', substr($buf, 11, 4);
  $header{timestamp}       = unpack 'V', substr($buf, 15, 4);

  my $filename_length = ord(substr($buf, 21, 1));
  $header{filename}   = substr($buf, 22, $filename_length);
  $header{filename}   =~ s/\0.*//s;
  $header{crc16}      = unpack 'v', substr($buf, 22 + $filename_length, 2);
  $header{os}         = _os_id( substr($buf, 24 + $filename_length, 1) );

  my $ext_from = 25 + $filename_length;
  my $ext_to   = $size - 3;
  if ($ext_from < $ext_to) {
    my (undef, $ext) = _extended_header_buf($buf, $ext_from, $ext_to - $ext_from + 2);
    %header = (%header, %{ $ext }) if %{ $ext };
  }

  my $extended_size_total = 0;
  my $extended_size = unpack 'v', substr($buf, -2, 2);
  while ($extended_size) {
    my $chunk = $stream->read($extended_size);
    $extended_size_total += $extended_size;
    my ($next, $hash) = _extended_header_buf($chunk, 0, $extended_size);
    %header = (%header, %{ $hash }) if %{ $hash };
    $extended_size = $next;
  }
  $header{encoded_size} = $header{skip_size} - $extended_size_total;

  $header{data_top}    = $start + $size + $extended_size_total;
  $header{next_header} = $header{data_top} + $header{encoded_size};

  bless \%header, $class;
}

1;

__END__

=head1 NAME

Archive::Lha::Header::Level1

=head1 DESCRIPTION

You usually don't need to use this directly. See L<Archive::Lha::Header> for examples.

This parses Level 1 headers found mainly in older archives created in the MS-DOS era. Also, some of the older ports, including LHa for UNIX, still prefer this header for compatibility reasons. Historically, Level 1 header, which is actually a combination of previous Level 0 header and following Level 2 header, was designed to foster the transition to Level 2 header. However, as Level 2 implementation delayed, Level 1 archives prevailed enough and could not be ignored.

Level 1 header also has rather severe limitation for the path length of the archived file. However, Level 1 header can use extended headers to store longer file/directory names. Multibyte strings in the header may be encoded in shift-jis, or in euc-jp, or in other encodings.

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
