package Crypt::OpenToken;

use Moose;
use Fcntl qw();
use Carp qw(croak);
use MIME::Base64 qw(encode_base64 decode_base64);
use Compress::Zlib;
use Digest::SHA1;
use Digest::HMAC_SHA1;
use Data::Dumper qw(Dumper);
use Crypt::OpenToken::KeyGenerator;
use Crypt::OpenToken::Serializer;
use Crypt::OpenToken::Token;

our $VERSION = '0.08';
our $DEBUG   = 0;

# shared encryption password
has 'password' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

# http://tools.ietf.org/html/draft-smith-opentoken-02
use constant TOKEN_PACK =>
   'a3'.    # literal 'OTK'
   'C'.     # version (unsigned-byte)
   'C'.     # cipher
   'a20'.   # hmac string (20 bytes for SHA1/SHA1_HMAC)
   'C/a*'.  # IV (with unsigned-byte length-prefix)
   'C/a*'.  # key (with unsigned-byte length-prefix)
   'n/a*';  # payload (with network-endian short length-prefix)

# List of ciphers supported by OpenToken
use constant CIPHER_NULL   => 0;
use constant CIPHER_AES256 => 1;
use constant CIPHER_AES128 => 2;
use constant CIPHER_DES3   => 3;
use constant CIPHERS       => [qw(null AES256 AES128 DES3)];

sub _cipher {
    my ($self, $cipher) = @_;

    my $impl = CIPHERS->[$cipher];
    croak "unsupported OTK cipher; '$cipher'" unless ($impl);

    my $mod = "Crypt::OpenToken::Cipher::$impl";
    eval "require $mod";
    if ($@) {
        croak "unable to load cipher '$impl'; $@";
    }
    print "selected cipher: $impl\n" if $DEBUG;
    return $mod->new;
}

sub parse {
    my ($self, $token_str) = @_;
    print "parsing token: $token_str\n" if $DEBUG;

    # base64 decode the OTK
    $token_str = $self->_base64_decode($token_str);

    # unpack the OTK token into its component fields
    my $fields = $self->_unpack($token_str);
    print "unpacked fields: " . Dumper($fields) if $DEBUG;

    # get the chosen cipher, and make sure the IV length is valid
    my $cipher = $self->_cipher( $fields->{cipher} );
    my $iv_len = $fields->{iv_len};
    unless ($iv_len == $cipher->iv_len) {
        croak "invalid IV length ($iv_len) for selected cipher ($cipher)";
    }

    # generate a decryption key for this cipher
    my $key = Crypt::OpenToken::KeyGenerator::generate(
        $self->password, $cipher->keysize,
    );
    print "generated key: " . encode_base64($key) if $DEBUG;

    # decrypt the payload
    my $crypto    = $cipher->cipher($key, $fields->{iv});
    my $decrypted = $crypto->decrypt($fields->{payload});
    print "decrypted payload: " . encode_base64($decrypted) if $DEBUG;

    # uncompress the payload
    my $plaintext = Compress::Zlib::uncompress($decrypted);
    print "plaintext:\n$plaintext\n" if $DEBUG;

    # verify the HMAC
    my $hmac = $self->_create_hmac($key, $fields, $plaintext);
    unless ($hmac eq $fields->{hmac}) {
        croak "invalid HMAC";
    }

    # deserialize the plaintext payload
    my %params = Crypt::OpenToken::Serializer::thaw($plaintext);
    print "payload: " . Dumper(\%params) if $DEBUG;
    $fields->{data} = \%params;

    # instantiate the token object
    my $token = Crypt::OpenToken::Token->new($fields);
    return $token;
}

sub create {
    my ($self, $cipher, $data) = @_;

    # get the chosen cipher, and generate a random IV for the encryption
    my $cipher_obj = $self->_cipher($cipher);
    my $iv         = '';
    if (my $len = $cipher_obj->iv_len) {
        $iv = _rand_iv($len);
    }

    # generate an encryption key for this cipher
    my $key = Crypt::OpenToken::KeyGenerator::generate(
        $self->password, $cipher_obj->keysize,
    );
    print "generated key: " . encode_base64($key) if $DEBUG;

    # serialize the data into a payload
    my $plaintext = Crypt::OpenToken::Serializer::freeze(%{$data});
    print "plaintext:\n$plaintext\n" if $DEBUG;

    # compress the payload
    my $compressed = Compress::Zlib::compress($plaintext);
    print "compressed plaintext: " . encode_base64($compressed) if $DEBUG;

    # encrypt the token, w/PKCS5 padding
    my $crypto    = $cipher_obj->cipher($key, $iv);
    my $padded    = $self->_pkcs5_padded($compressed, $crypto->blocksize());
    my $encrypted = $crypto->encrypt($padded);
    print "encrypted payload: " . encode_base64($encrypted) if $DEBUG;

    # gather up all of the fields
    my %fields = (
        version     => 1,
        cipher      => $cipher,
        iv_len      => bytes::length($iv),
        iv          => $iv,
        key_len     => bytes::length($key),
        key         => $key,
        payload_len => bytes::length($encrypted),
        payload     => $encrypted,
    );

    # create an HMAC
    my $hmac = $self->_create_hmac($key, \%fields, $plaintext);
    print "calculated hmac: " . encode_base64($hmac) if $DEBUG;
    $fields{hmac} = $hmac;

    # pack the OTK token together from its component fields
    my $token = $self->_pack(%fields);
    print "binary token: $token\n" if $DEBUG;

    # base64 encode the token
    my $token_str = $self->_base64_encode($token);
    print "token created: $token_str\n" if $DEBUG;
    return $token_str;
}

sub _rand_iv {
    my $len = shift;
    my $iv  = '';
    use bytes;

    # try to use a reasonably unguessable source of random bytes.
    # /dev/random isn't needed for IVs in general.
    eval {
        sysopen my $urand, '/dev/urandom', Fcntl::O_RDONLY() or die $!;
        binmode $urand or die $!;
        sysread $urand, $iv, $len or die $!;
    };
    warn __PACKAGE__."::_rand_iv can't use /dev/urandom: $@" if $@;

    # fill up with less random bytes
    if (length($iv) < $len) {
        $iv .= chr(int(rand(256))) until (length($iv) == $len);
    }

    return $iv;
}

sub _pkcs5_padded {
    my ($self, $data, $bsize) = @_;
    if ($bsize) {
        my $data_len   = bytes::length($data);
        my $pad_needed = $bsize - ($data_len % $bsize);
        $data .= chr($pad_needed) x $pad_needed;
    }
    return $data;
}

sub _create_hmac {
    my ($self, $key, $fields, $plaintext) = @_;

    # NULL cipher uses SHA1 digest, all other ciphers use an HMAC_SHA1
    my $digest =
        ($fields->{cipher} == CIPHER_NULL)
        ? Digest::SHA1->new()
        : Digest::HMAC_SHA1->new($key);

    $digest->add(chr($fields->{version}));
    $digest->add(chr($fields->{cipher}));
    $digest->add($fields->{iv})  if ($fields->{iv_len} > 0);
    $digest->add($fields->{key}) if ($fields->{key_len} > 0);
    $digest->add($plaintext);

    return $digest->digest;
}

sub _unpack {
    my ($self, $token_str) = @_;
    use bytes;

    my ($otk, $ver, $cipher, $hmac, $iv, $key, $payload)
        = unpack(TOKEN_PACK, $token_str);
    unless ($otk eq 'OTK') {
        croak "invalid literal identifier in OTK; '$otk'";
    }
    unless ($ver == 1) {
        croak "unsupported OTK version; '$ver'";
    }

    return {
        version     => $ver,
        cipher      => $cipher,
        hmac        => $hmac,
        iv_len      => length($iv),
        iv          => $iv,
        key_len     => length($key),
        key         => $key,
        payload_len => length($payload),
        payload     => $payload,
    };
}

sub _pack {
    my ($self, %fields) = @_;

    # truncate to specified lengths
    for (qw(iv key payload)) {
        substr($fields{$_}, $fields{ $_ . "_len" }) = '';
    }

    my $token_str = pack(TOKEN_PACK,
        'OTK', @fields{qw(version cipher hmac iv key payload)}
    );
    return $token_str;
}

# Custom Base64 decoding; OTK has some oddities in how they encode things
# using Base64.
sub _base64_decode {
    my ($self, $token_str) = @_;

    # fixup: convert trailing "*"s into "="s (OTK specific encoding)
    $token_str =~ s/(\*+)$/'=' x length($1)/e;

    # fixup: convert "_" to "/" (PingId PHP bindings encode this way)
    # fixup: convert "-" to "+" (PingId PHP bindings encode this way)
    $token_str =~ tr{_-}{/+};

    # Base64 decode it, and we're done.
    my $decoded = decode_base64($token_str);
    return $decoded;
}

# Custom Base64 encoding; OTK has some oddities in how they encode things
# using Base64.
sub _base64_encode {
    my ($self, $token_str) = @_;

    # Base64 encode the token string
    my $encoded = encode_base64($token_str, '');

    # fixup: convert "+" to "-" (PingId PHP bindings encode this way)
    # fixup: convert "/" to "_" (PingId PHP bindings encode this way)
    $encoded =~ tr{/+}{_-};

    # fixup: convert trailing "="s to "*"s (OTK specific encoding)
    $encoded =~ s/(\=+)$/'*' x length($1)/e;

    return $encoded;
}

no Moose;

1;

=head1 NAME

Crypt::OpenToken - Perl implementation of Ping Identity's "OpenToken"

=head1 SYNOPSIS

  use Crypt::OpenToken;

  $data = {
      foo => 'bar',
      bar => 'baz',
  };

  # create an OpenToken factory based on a given shared password
  $factory = Crypt::OpenToken->new($password);

  # encrypt a hash-ref of data into an OpenToken.
  $token_str = $factory->create(
      Crypt::OpenToken::CIPHER_AES128,
      $data,
  );

  # decrypt an OpenToken, check if its valid, and get data back out
  $token = $factory->parse($token_str);
  if ($token->is_valid) {
      $data = $token->data();
  }

=head1 DESCRIPTION

This module provides a Perl implementation of the "OpenToken" standard as
defined by Ping Identity in their IETF Draft.

=head1 METHODS

=over

=item Crypt::OpenToken->new($password)

Instantiates a new OpenToken factory, which can encrypt/decrypt OpenTokens
using the specified shared C<$password>.

=item $factory->create($cipher, $data)

Encrypts the given hash-ref of C<$data> using the specified C<$cipher> (which
should be one of the C<CIPHER_*> constants).

Returns back to the caller a Base64 encoded string which represents the
OpenToken.

B<NOTE:> during the encryption of the OpenToken, a random Initialization
Vector will be selected; as such it is I<not> possible to encrypt the same
data more than once and get the same OpenToken back.

=item $factory->parse($token)

Decrypts a Base64 encoded OpenToken, returning a C<Crypt::OpenToken::Token>
object back to the caller.  Throws a fatal exception in the event of an error.

It is the callers responsibility to then check to see if the token itself is
valid (see L<Crypt::OpenToken::Token> for details).

=back

=head1 CONSTANTS

The following constant values are available for selecting an encrytion cipher
to use:

=over

=item Crypt::OpenToken::CIPHER_NULL

"Null" encryption (e.g. no encryption whatsoever).  Requires C<Crypt::NULL>.

=item Crypt::OpenToken::CIPHER_AES256

"AES" encryption, 256-bit.  Requires C<Crypt::Rijndael>.

=item Crypt::OpenToken::CIPHER_AES128

"AES" encryption, 128-bit.  Requires C<Crypt::Rijndael>.

=item Crypt::OpenToken::CIPHER_DES3

"TripleDES" encryption, 168-bit.  Requires C<Crypt::DES>.

=back

=for Pod::Coverage CIPHERS TOKEN_PACK

=head1 CAVEATS

=over

=item *

This module does not (yet) support the "obfuscate password" option that is
configurable within PingFederate's OpenToken adapter.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

Shawn Devlin (shawn.devlin@socialtext.com)

=head2 Contributors

Thanks to those who have provided feedback, comments, and patches:

  Jeremy Stashewsky
  Travis Spencer

=head2 Sponsors

B<BIG> thanks also go out to those who sponsored C<Crypt::OpenToken>:

=over

=item Socialtext

Thanks for sponsoring the initial development of C<Crypt::OpenToken>, and then
being willing to release it to the world.

=item Ping Identity

Thanks for your assistance during the initial development, providing feedback
along the way, and answering our questions as they arose.

=back

=head1 COPYRIGHT & LICENSE

=head2 Crypt::OpenToken

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=head2 OpenToken specification

The OpenToken specification is Copyright (C) 2007-2010 Ping Identity
Corporation, and released under the MIT License:

=over

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

=back

=head1 SEE ALSO

L<http://tools.ietf.org/html/draft-smith-opentoken-02>
L<http://www.pingidentity.com/opentoken>

=cut
