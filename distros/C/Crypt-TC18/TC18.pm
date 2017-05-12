package Crypt::TC18;

use strict;
use warnings;
require Exporter;

our @EXPORT_OK = qw(keysize blocksize new encrypt decrypt rounds);
our $VERSION = '1.0.0';
our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Crypt::TC18', $VERSION);

# Preloaded methods go here.

sub keysize { 8 }
sub blocksize { 16 }
sub rounds { 16 }      # may be useful in some applications

1;

__END__

=head1 NAME

Crypt::TC18 - Crypt::CBC compliant block cipher

=head1 ABSTRACT

B<TC18> is 128-bit block cipher that accepts a 64-bit key. TC18 is also
known as B<XSM>.

=head1 SYNOPSIS

    use Crypt::TC18;

    $cipher = new Crypt::TC18 $key;

    $ciphertext = $cipher->encrypt($plaintext);
    $plaintext  = $cipher->decrypt($ciphertext);

    $bs = $cipher->blocksize;
    $ks = $cipher->keysize;
    $r = $cipher->rounds;

=head1 DESCRIPTION

TC18 is 128-bit block cipher that accepts a 64-bit key. It was
designed by Tom St. Denis.

This module supports the Crypt::CBC interface, with the following
functions.

=head2 Functions

=over

=item B<blocksize>

Returns the size (in bytes) of the block (16, in this case)

=item B<keysize>

Returns the size (in bytes) of the key (8, in this case)

=item B<rounds>

Returns the number of rounds used by TC18 (16, in this case)

=item B<encrypt($data)>

Encrypts 16 bytes of $data and returns the corresponding ciphertext

=item B<decrypt($data)>

Decrypts 16 bytes of $data and returns the corresponding plaintext

=back

=head1 EXAMPLES

See the "examples" directory for some examples

=head1 SEE ALSO

B<Crypt::Anubis>, B<Crypt::Camellia>, B<Crypt::Khazad>,
B<Crypt::Loki97>, B<Crypt::Misty1>, B<Crypt::Noekeon>,
B<Crypt::Rainbow>, B<Crypt::Shark>, B<Crypt::Skipjack>, and
B<Crypt::Square>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Julius C. Duque. Please read B<contact.html> that
comes with this distribution for details on how to contact the author.

This library is free software; you can redistribute it and/or modify
it under the same terms as the GNU General Public License.

=cut

