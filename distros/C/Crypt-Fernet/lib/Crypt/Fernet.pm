package Crypt::Fernet;

use 5.018002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::Fernet ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
  fernet_genkey fernet_encrypt fernet_verify fernet_decrypt	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

our $FERNET_TOKEN_VERSION = pack("H*", '80');


# Preloaded methods go here.

sub fernet_genkey { Crypt::Fernet::generate_key() }
sub fernet_encrypt  { Crypt::Fernet::encrypt(@_) }
sub fernet_verify  { Crypt::Fernet::verify(@_) }
sub fernet_decrypt { Crypt::Fernet::decrypt(@_) }


use Crypt::CBC;
use Digest::SHA qw(hmac_sha256);
use MIME::Base64::URLSafe;

sub generate_key {
    return _urlsafe_pading_base64_encode(Crypt::CBC->random_bytes(32));
}

sub encrypt {
    my ($key, $data) = @_;
    my $b64decode_key = urlsafe_b64decode($key);
    my $signkey = substr $b64decode_key, 0, 16;
    my $encryptkey = substr $b64decode_key, 16, 16;
    my $iv = Crypt::CBC->random_bytes(16);
    my $cipher = Crypt::CBC->new(-literal_key => 1,
                                 -key         => $encryptkey,
                                 -iv          => $iv,
                                 -keysize     => 16,
                                 -blocksize   => 16,
                                 -padding     => 'standard',
                                 -cipher      => 'Rijndael',
                                 -header      => 'none',
                             );
    my $ciphertext = $cipher->encrypt($data);
    my $pre_token = $FERNET_TOKEN_VERSION . _timestamp() . $iv . $ciphertext;
    my $digest=hmac_sha256($pre_token, $signkey);
    my $token = $pre_token . $digest;
    return _urlsafe_pading_base64_encode($token);
}

sub decrypt {
    my ($key, $token, $ttl) = @_;
    verify($key, $token, $ttl) or return;
    my $b64decode_key = urlsafe_b64decode($key);
    my $token_data = urlsafe_b64decode($token);

    my $encryptkey = substr $b64decode_key, 16, 16;
    my $iv = substr $token_data, 9, 16;

    my $ciphertextlen = (length $token_data) - 25 - 32;
    my $ciphertext = substr $token_data, 25, $ciphertextlen;
 
    my $cipher = Crypt::CBC->new(-literal_key => 1,
                                 -key         => $encryptkey,
                                 -iv          => $iv,
                                 -keysize     => 16,
                                 -blocksize   => 16,
                                 -padding     => 'standard',
                                 -cipher      => 'Rijndael',
                                 -header      => 'none',
                             );
    my $plaintext = $cipher->decrypt($ciphertext);
    return $plaintext; 
}

sub verify {
    my ($key, $token, $ttl) = @_;
    $ttl ||= 0;
    my $b64decode_key = urlsafe_b64decode($key);
    my $msg = urlsafe_b64decode($token);
    my $token_version = substr $msg, 0, 1;
    ($token_version eq $FERNET_TOKEN_VERSION) or return 0;

    if ($ttl > 0) {
        my $timestamp_bytes = substr $msg, 1, 8;
        my $timestamp = _byte_to_time($timestamp_bytes);
        return 0 if (time - $timestamp > $ttl);
    }    

    my $token_sign = substr $msg, (length $msg) - 32, 32;
    my $signkey = substr $b64decode_key, 0, 16;
    my $pre_token = substr $msg, 0, (length $msg) - 32;
    my $verify_digest = hmac_sha256($pre_token , $signkey);
    ($token_sign eq $verify_digest) and return 1;
    return 0;
}

sub _timestamp {
    use bytes;
    my $time = time;
    my $time64bit;
    for my $index (0..7) {
        $time64bit .= substr pack("I", ($time >> $index * 8) & 0xFF), 0, 1;
    }
    my $result = reverse $time64bit;
    no bytes;
    return $result;
}

sub _urlsafe_pading_base64_encode {
    my ($msg) = @_;
    my $s = urlsafe_b64encode($msg);
    return $s.("=" x (4 - length($s) % 4));
}

sub _byte_to_time {
    my ($bytes) = @_;
    use bytes;
    my $rb =  reverse $bytes;
    my $time = unpack 'V', $rb;
    return $time;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::Fernet - Perl extension for Fernet (symmetric encryption) 

=head1 SYNOPSIS

  use Crypt::Fernet;

  my $key = Crypt::Fernet::generate_key();
  my $plaintext = 'This is a test';
  my $token = Crypt::Fernet::encrypt($key, $plaintext);
  my $verify = Crypt::Fernet::verify($key, $token);
  my $decrypttext = Crypt::Fernet::decrypt($key, $token);

  my $old_key = 'cJ3Fw3ehXqef-Vqi-U8YDcJtz8Gv-ZHyxultoAGHi4c=';
  my $old_token = 'gAAAAABT8bVcdaked9SPOkuQ77KsfkcoG9GvuU4SVWuMa3ewrxpQdreLdCT6cc7rdqkavhyLgqZC41dW2vwZJAHLYllwBmjgdQ==';

  my $ttl = 10;
  my $old_verify = Crypt::Fernet::verify($old_key, $old_token, $ttl);
  my $old_decrypttext = Crypt::Fernet::decrypt($old_key, $old_token, $ttl);

  my $ttl_verify = Crypt::Fernet::verify($key, $token, $ttl);
  my $ttl_decrypttext = Crypt::Fernet::decrypt($key, $token, $ttl);


=head1 DESCRIPTION

Fernet provides guarantees that a message encrypted using it cannot be manipulated or read without the key. Fernet is an implementation of symmetric (also known as "secret key") authenticated cryptography.
This is the Perl Implementation

More Detail:
   https://github.com/fernet/spec/blob/master/Spec.md

=head2 EXPORT

None by default.



=head1 SEE ALSO

More Detail on the Fernet Spec:
   https://github.com/fernet/spec/blob/master/Spec.md

Source of this project:
   https://github.com/wanleung/Crypt-Fernet

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  use Crypt::CBC;
  use Digest::SHA qw(hmac_sha256);
  use MIME::Base64::URLSafe;

=head1 AUTHOR

Wan Leung Wong, E<lt>wanleung@linkomnia.comE<gt>

=head1 COPYRIGHT AND LICENSE

The MIT License (MIT)

Copyright (C) 2014 LinkOmnia Ltd (Wan Leung Wong wanleung@linkomnia.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
