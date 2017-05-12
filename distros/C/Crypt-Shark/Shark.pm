package Crypt::Shark;

use strict;
use warnings;
require Exporter;

our @EXPORT_OK = qw(keysize blocksize new encrypt decrypt);
our $VERSION = '1.0.1';
our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Crypt::Shark', $VERSION);

# Preloaded methods go here.

1;

__END__

=head1 NAME

Crypt::Shark - Crypt::CBC compliant block cipher

=head1 ABSTRACT

Shark is 64-bit block cipher that accepts a 128-bit key.

=head1 SYNOPSIS

    use Crypt::Shark;

    $cipher = new Crypt::Shark $key;
    $ciphertext = $cipher->encrypt($plaintext);
    $plaintext  = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

Shark is 64-bit block cipher that accepts a 128-bit key. It was
designed by Vincent Rijmen, Joan Daemen, Bart Preneel, Antoon
Bosselaers, and Erik De Win.

This module supports the Crypt::CBC interface, with the following
functions.

=head2 Functions

=over

=item B<blocksize>

Returns the size (in bytes) of the block (8, in this case).

=item B<keysize>

Returns the size (in bytes) of the key (16, in this case).

=item B<encrypt($data)>

Encrypts 8 bytes of $data and returns the corresponding ciphertext.

=item B<decrypt($data)>

Decrypts 8 bytes of $data and returns the corresponding plaintext.

=back

=head1 EXAMPLE 1

    #!/usr/local/bin/perl

    use diagnostics;
    use strict;
    use warnings;
    use Crypt::Shark;

    # key must be 16 bytes long
    my $key = "0123456789abcdef";

    my $cipher = new Crypt::Shark $key;

    print "blocksize = ", $cipher->blocksize, " bytes \n";
    print "keysize = ", $cipher->keysize, " bytes \n";

    # block must be 8 bytes long
    my $plaintext1 = "01234567";

    my $ciphertext = $cipher->encrypt($plaintext1);
    my $plaintext2 = $cipher->decrypt($ciphertext);

    print "Decryption OK\n" if ($plaintext1 eq $plaintext2);

=head1 EXAMPLE 2

    #!/usr/local/bin/perl

    use diagnostics;
    use strict;
    use warnings;
    use Crypt::CBC;  # CBC automatically loads Shark for us

    # when using Crypt::CBC, key may be of ANY length
    my $key = "0123456789abcdef";

    # IV must be exactly 16 bytes long
    my $IV = pack "H16", 0;

    my $cipher = Crypt::CBC->new({'key' => $key,
                                  'cipher' => 'Shark',
                                  'iv' => $IV,
                                  'regenerate_key' => 1,
                                  'padding' => 'standard',
                                  'prepend_iv' => 0
                                });

    # when using Crypt::CBC, plaintext may be of ANY length
    my $plaintext1 = "This is a test";

    my $ciphertext = $cipher->encrypt($plaintext1);
    my $plaintext2 = $cipher->decrypt($ciphertext);

    print "Decryption OK\n" if ($plaintext1 eq $plaintext2);

=head1 MORE EXAMPLES

See B<Crypt::CBC> for more examples using CBC mode. See also the
"examples" and "t" directories for some more examples.

=head1 SEE ALSO

B<Crypt::Khazad>, B<Crypt::Misty1>, B<Crypt::Anubis>,
B<Crypt::Noekeon>, B<Crypt::Skipjack>, B<Crypt::Camellia>,
B<Crypt::Square>, and B<Crypt::Rainbow>.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Julius C. Duque. Please read B<contact.html> that
comes with this distribution for details on how to contact the author.

This library is free software; you can redistribute it and/or modify
it under the same terms as the GNU General Public License.

=cut

