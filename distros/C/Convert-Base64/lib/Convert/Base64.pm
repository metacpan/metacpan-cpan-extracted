package Convert::Base64;
$Convert::Base64::VERSION = '0.001';
# ABSTRACT: Encoding and decoding of Base64 strings

use strict;
use warnings;
use MIME::Base64 ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(encode_base64 decode_base64);

sub encode_base64 { @_ = ($_[0], ''); goto &MIME::Base64::encode; }
*decode_base64 = \&MIME::Base64::decode;

1;

=head1 NAME

Convert::Base64 - Encoding and decoding of Base64 strings

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Convert::Base64;

  $encoded = encode_base64("\x3a\x27\x0f\x93");
  $decoded = decode_base64($encoded);


=head1 DESCRIPTION

This module provides functions to convert strings to/from the Base64 encoding
as described in RFC 4648.

Its implemented as a light wrapper over L<MIME::Base64>.

=head1 FUNCTIONS

=over 4

=item *

C<encode_base64>

    my $encoded = encode_base64("foo");

Encode a string of bytes into its Base64 representation.

=item *

C<decode_base64>

    my $decoded = encode_base64("Zm9v");

Decode a Base64 string into a string of bytes.

=back

=head1 SEE ALSO

=over 4

=item *

L<MIME::Base64> - the classic Base64 implementation for Perl, used internally
by this module

=item *

L<Convert::Base32> - the original inspiration for this module

=item *

L<http://tools.ietf.org/html/rfc4648> - the Base64 specification

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report bugs or feature requests through the issue tracker at
L<https://github.com/robn/Convert-Base64/issues>. You will be notified
automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Convert-Base64>

  git clone https://github.com/robn/Convert-Base64.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
