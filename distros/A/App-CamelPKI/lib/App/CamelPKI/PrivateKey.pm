#!perl -w

package App::CamelPKI::PrivateKey;
use strict;

=head1 NAME

B<App::CamelPKI::PrivateKey> - Modelise a private key in Camel-PKI.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use App::CamelPKI::PrivateKey;

  my $key = parse App::CamelPKI::PrivateKey($pemstring, -format => "PEM");

  my $derstring = $key->serialize(-format => "DER");

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

This class modelise a private key in Camel-PKI. Each instance is immutable
and represents an RSA key, in text mode protected by a passphrase, or 
stored in a pincard or any other HSM.

=cut

use Crypt::OpenSSL::CA 0.06;
use App::CamelPKI::Error;
use App::CamelPKI::PublicKey;
use base "App::CamelPKI::PEM";

sub _marker { "RSA PRIVATE KEY" }

=head1 METHODS

=head2 genrsa($keysize)

Generates and returns a new RSA key of $keysize size.

=cut

sub genrsa {
    my ($class, $keysize) = @_;
    return $class->parse(scalar(`openssl genrsa $keysize 2>/dev/null`));
}

=head2 get_public_key

Returns an instance of L<App::CamelPKI::PublicKey>.

=cut

sub get_public_key {
    App::CamelPKI::PublicKey->parse
        (shift->as_crypt_openssl_ca_privatekey->get_public_key->to_PEM);
}

=head2 as_crypt_openssl_ca_privatekey()

Returns an instance of L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::PrivateKey>
which modelise the certificate, with a cache.

=cut

sub as_crypt_openssl_ca_privatekey {
    my ($self) = @_;
    # FIXME: find a way to avoid having the key in clearform in memory
    # at this precise time.
    $self->{cocx} ||= Crypt::OpenSSL::CA::PrivateKey->parse
        ($self->serialize());
}

=head2 get_modulus()

Performs the same job as the method of the same name in
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::PrivateKey>

=cut

sub get_modulus { shift->as_crypt_openssl_ca_privatekey->get_public_key->get_modulus }

=begin internals

=cut

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Test qw(%test_keys_plaintext);
use App::CamelPKI::Error;

test "round trip" => sub {
    my $key = $test_keys_plaintext{"rsa1024"};
    is(App::CamelPKI::PrivateKey->parse($key)->serialize(), $key,
       "round trip");
};

test "->genrsa->get_public_key" => sub {
    ok(App::CamelPKI::PrivateKey->genrsa(1024)->get_public_key
       ->isa("App::CamelPKI::PublicKey"));
};

test "Not parsing Public Key"  => sub{
	my $pubKey = "-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC+65Bvt5SRLNzWR1r6b9wBUnY4
z6OzkrgA/5q08q8KRFBZFkiajdxzdLzE4N+Mkzod1nvm8JSR+ygZkxEkbsk9mBOM
qXTefi65snPKfwAoseZlKShCLQpjNvsbZ5LuKKmbexas8aCc5mysyznm2KfBwk00
7oJd54rtss2X4TniGwIDAQAB
-----END PUBLIC KEY-----
";
	try {
		App::CamelPKI::PrivateKey->parse($pubKey);
		fail;
	} catch Error with {pass;};
};


test "->get_modulus" => sub {
    my $pubkey = App::CamelPKI::PrivateKey->parse($test_keys_plaintext{"rsa1024"});
    is($pubkey->get_modulus,
       $pubkey->as_crypt_openssl_ca_privatekey->get_public_key->get_modulus);
};

=end internals

=cut
