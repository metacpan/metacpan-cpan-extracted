package Archive::Lha::Header::Level2;

use strict;
use warnings;
use Carp;
use Archive::Lha::Header::Base;
use Archive::Lha::Header::Utils;

sub new {
  my ($class, $stream) = @_;

  my $start = $stream->tell;
  my $size  = unpack 'v', $stream->read(2);

  croak "Header is broken: size is null" unless $size;
  croak "Header is too large: $size" if $size > 4096;

  $stream->seek($start);
  my $buf = $stream->read($size);

  my %header;
  $header{header_top}    = $start;
  $header{header_size}   = $size;
  $header{method}        = substr($buf, 3, 3);
  $header{encoded_size}  = unpack 'V', substr($buf,  7, 4);
  $header{original_size} = unpack 'V', substr($buf, 11, 4);
  $header{timestamp}         = unpack 'V', substr($buf, 15, 4);
  $header{timestamp_is_unix} = 1;
  $header{crc16}         = unpack 'v', substr($buf, 21, 2);
  $header{os}            = _os_id( substr($buf, 23, 1) );
  $header{data_top}      = $start + $size;
  $header{next_header}   = $header{data_top} + $header{encoded_size};

  my $from          = 26;
  my $extended_size = unpack 'v', substr($buf, 24, 2);
  while ($extended_size) {
    my ($next, $hash) = _extended_header_buf($buf, $from, $extended_size);
    %header = (%header, %{ $hash }) if %{ $hash };
    $from         += $extended_size;
    $extended_size = $next;
  }

  bless \%header, $class;
}

1;

__END__

=head1 NAME

Archive::Lha::Header::Level2

=head1 DESCRIPTION

You usually don't need to use this directly. See L<Archive::Lha::Header> for examples.

This parses Level 2 headers found in the recent archives. Level 2 header uses extended headers to store longer file/directory names.

=head1 METHODS

=head2 new

parses a stream and creates an object.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
