package Crypt::Misty1;

use strict;
use warnings;
require Exporter;

our @EXPORT_OK = qw(keysize blocksize new encrypt decrypt);
our $VERSION = '1.1.3';
our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Crypt::Misty1', $VERSION);

# Preloaded methods go here.

1;

__END__

=head1 NAME

Crypt::Misty1 - Crypt::CBC-compliant block cipher

=head1 ABSTRACT

Misty1 is a 128-bit key, 64-bit block cipher. Designed by Mitsuru
Matsui, the inventor of linear cryptanalysis, Misty1 is the first
cipher that is provably secure against linear and differential
cryptanalysis.

=head1 SYNOPSIS

    use Crypt::Misty1;

    $cipher = new Crypt::Misty1 $key;
    $ciphertext = $cipher->encrypt($plaintext);
    $plaintext  = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

Misty1 is a 64-bit symmetric block cipher with a 128-bit key. It was
developed by Mitsuru Matsui, and is described in the paper B<New Block
Encryption Algorithm MISTY> and in B<RFC2994>. 

In January of 2000, the 3GPP consortium selected a variant of Misty1,
dubbed as KASUMI (the Japanese word for ``misty''), as the mandatory
cipher in W-CDMA.

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
    use Crypt::Misty1;

    # key must be 16 bytes long
    my $key = "0123456789abcdef";

    my $cipher = new Crypt::Misty1 $key;

    print "blocksize = ", $cipher->blocksize, " bytes \n";
    print "keysize = ", $cipher->keysize, " bytes \n";

    # block must be 8 bytes long
    my $plaintext1 = "Testing1";

    my $ciphertext = $cipher->encrypt($plaintext1);
    my $plaintext2 = $cipher->decrypt($ciphertext);

    print "Decryption OK\n" if ($plaintext1 eq $plaintext2);

=head1 EXAMPLE 2

    #!/usr/local/bin/perl

    use diagnostics;
    use strict;
    use warnings;
    use Crypt::CBC;  # CBC automatically loads Misty1 for us

    # when using Crypt::CBC, key may be of ANY length
    my $key = "0123456789abcdef";

    # IV must be exactly 8 bytes long
    my $IV = pack "H16", 0;

    my $cipher = Crypt::CBC->new({'key' => $key,
                                  'cipher' => 'Misty1',
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

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Julius C. Duque <jcduque (AT) lycos (DOT) com>

This library is free software; you can redistribute it and/or modify
it under the same terms as the GNU General Public License.

=cut

