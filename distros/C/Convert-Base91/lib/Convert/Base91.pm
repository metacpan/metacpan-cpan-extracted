package Convert::Base91;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;

our @EXPORT_OK = qw/encode_base91 decode_base91/;
our @EXPORT = ();

our $VERSION = '0.001';

require XSLoader;
XSLoader::load('Convert::Base91', $VERSION);

our $base91 = __PACKAGE__->new;

sub encode_base91 {
	my ($data) = @_;
	$base91->encode($data);
	$base91->encode_end;
}

sub decode_base91 {
	my ($data) = @_;
	$base91->decode($data);
	$base91->decode_end;
}

1;
__END__

=encoding utf-8

=head1 NAME

Convert::Base91 - XS base91 encoding/decoding

=head1 SYNOPSIS

  use Convert::Base91 qw/encode_base91 decode_base91/;

  # procedural interface
  my $encoded = encode_base91 'some data';
  say $encoded; # qrLg,W;Hr%w
  my $decoded = decode_base91 $encoded;
  say $decoded; # some data


  # OO interface
  my $base91 = Convert::Base91->new;
  $base91->encode('some ');
  $base91->encode('data');
  my $enc = $base91->encode_end;
  say $enc; # qrLg,W;Hr%w

  $base91->decode('qrLg,');
  $base91->decode('W;Hr%w');
  my $dec = $base91->decode_end;
  say $dec; # some data

=head1 DESCRIPTION

Base91 is a method for encoding binary data as printable ASCII
characters. Every two base91 characters (16 bits) encode 13 or 14 bits
of actual data, thus the overhead is between 14% and 23%, an
improvement over base64's overhead of 33%.

This module provides a procedural interface for encoding/decoding
whole strings and an OO interface for encoding/decoding in chunks.

The C<encode_base91> and C<decode_base91> functions are available for
export, but are not exported by default.

=over

=item B<encode_base91> $binary_data

Takes a string containing arbitrary bytes and returns the
base91 encoded data.

=item B<decode_base91> $base91_data

Takes a string containing base91 encoded data and returns the decoded
string of arbitrary bytes.

=item Convert::Base91->B<new>

Create a new C<Convert::Base91> object to keep the state for a chunk
encoding/decoding operation.

=item $base91->B<encode>($data)

Submit the next chunk of arbitrary binary data to be encoded. Returns
nothing.

=item $base91->B<encode_end>

Signals that all chunks of data to be encoded have been submitted.
Returns the base91 encoded data, and clears the state of the $base91
object so it may be used again (for either encoding or decoding).

=item $base91->B<decode>($data)

Submit the next chunk of base91 data to be decoded. Returns nothing.

=item $base91->B<decode_end>

Signals that all chunks of data to be decoded have been submitted.
Returns the decoded data, and clears the state of the $base91 object
so it may be used again (for either encoding or decoding).

=back

=head1 SEE ALSO

L<http://base91.sourceforge.net/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
