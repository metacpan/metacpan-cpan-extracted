package Crypt::Sodium::XS::Core;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my $hchacha20 = [qw[
  hchacha20
  hchacha20_CONSTBYTES
  hchacha20_KEYBYTES
  hchacha20_INPUTBYTES
  hchacha20_OUTPUTBYTES
]];

our %EXPORT_TAGS = (
  all => [ @$hchacha20 ],
  hchacha20 => $hchacha20,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::Core - libsodium low-level functions

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

L<Crypt::Sodium::XS::Core> provides an API to libsodium's core functions. These
low-level functions are not usually needed, and must only be used to implement
custom constructions.

=head1 FUNCTIONS

Nothing is exported by default. A C<:hchacha20> tag imports the L</hchacha20
FUNCTIONS AND CONSTANTS> functions and constants. A C<:all> tag imports
everything.

=head1 hchacha20 FUNCTIONS AND CONSTANTS

=head2 hchacha20

=head2 hchacha20_CONSTBYTES

=head2 hchacha20_INPUTBYTES

=head2 hchacha20_KEYBYTES

=head2 hchacha20_OUTPUTBYTES

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://doc.libsodium.org/advanced/scalar_multiplication>

=item L<https://doc.libsodium.org/key_derivation>

hchacha20 is documented here.

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

For any security sensitive reports, please email the author directly or contact
privately via IRC.

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
