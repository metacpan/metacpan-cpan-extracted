package Crypt::Sodium::XS::Base64;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

our %EXPORT_TAGS = (
  functions => [map { "sodium_$_" } qw[base642bin bin2base64]],
  constants => [qw[
    BASE64_VARIANT_ORIGINAL
    BASE64_VARIANT_ORIGINAL_NO_PADDING
    BASE64_VARIANT_URLSAFE
    BASE64_VARIANT_URLSAFE_NO_PADDING
  ]],
);
$EXPORT_TAGS{all} = [@{$EXPORT_TAGS{functions}}, @{$EXPORT_TAGS{constants}}];
our @EXPORT_OK = (@{$EXPORT_TAGS{functions}}, @{$EXPORT_TAGS{constants}});

1;

__END__

=encoding utf8

Crypt::Sodium::XS::Base64 - libsodium base64 functions and constants

=head1 SYNOPSIS

  use Crypt::Sodium::XS::Base64 ':all';

  my $b64 = sodium_bin2base64("foobar");
  my $bin = sodium_base642bin($b64);
  print "$bin\n";
  # foobar
  my $orig_b64 = sodium_bin2base64("barfoo", BASE64_VARIANT_ORIGINAL);
  print sodium_base642bin($orig_b64);
  # barfoo

=head1 DESCRIPTION

Provides access to the libsodium-provided base64 functions and constants.
IMPROVEME.

B<NOTE>: These functions are not intended for use with sensitive data.
L<Crypt::Sodium::XS::MemVault> provides much of the same functionality for use
with sensitive data.

=head1 FUNCTIONS

Nothing is exported by default. The tag C<:functions> imports all
L</FUNCTIONS>. The tag C<:all> imports everything.

=head2 sodium_base642bin

  my $bytes = sodium_base642bin($string);

No real advantage over L<MIME::Base64>. Stops parsing at any invalid base64
bytes. C<$bytes> will be empty if C<$string> could not be validly interpreted
as base64 (i.e., if the output would not be a multiple of 8 bits).

=head2 sodium_bin2base64

  my $string = sodium_bin2base64($bytes);
  my $string = sodium_bin2base64($bytes, $variant);

No real advantage over L<MIME::Base64>. For C<$variant>, see L</BASE64
CONSTANTS>. The default is L</BASE64_VARIANT_URLSAFE_NO_PADDING>.

=head1 CONSTANTS

Nothing is exported by default. The tag C<:constants> imports all
L</CONSTANTS>. The tag C<:all> imports everything.

=head2 BASE64_VARIANT_ORIGINAL

L<RFC 4648 Base 64 Encoding|https://www.rfc-editor.org/rfc/rfc4648#section-4>.

=head2 BASE64_VARIANT_ORIGINAL_NO_PADDING

L<RFC 4648 Base 64 Encoding|https://www.rfc-editor.org/rfc/rfc4648#section-4>
without C<=> padding.

=head2 BASE64_VARIANT_URLSAFE

L<RFC 4648 Base 64 Encoding with URL and Filename Safe
Alphabet|https://www.rfc-editor.org/rfc/rfc4648#section-5>.

=head2 BASE64_VARIANT_URLSAFE_NO_PADDING

L<RFC 4648 Base 64 Encoding with URL and Filename Safe
Alphabet|https://www.rfc-editor.org/rfc/rfc4648#section-5> without C<=>
padding.

=head1 SEE ALSO

=over 4

=item * L<libsodium|https://doc.libsodium.org/helpers#base64-encoding-decoding>

=back

=head1 FEEDBACK

For reporting bugs, giving feedback, submitting patches, etc. please use the
following:

=over 4

=item *

RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Crypt-Sodium-XS>

=item *

IRC channel C<#sodium> on C<irc.perl.org>.

=item *

Email the author directly.

=back

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2025 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
