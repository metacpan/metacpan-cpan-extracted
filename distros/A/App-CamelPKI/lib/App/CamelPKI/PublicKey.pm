#!perl -w

package App::CamelPKI::PublicKey;
use strict;

=head1 NAME

B<App::CamelPKI::PublicKey> - Public key model for App-PKI.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use App::CamelPKI::PublicKey;

  my $key = parse App::CamelPKI::PublicKey($pemstring, -format => "PEM");

  my $pemstring = $key->serialize(-format => "DER");

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

This class modelise a public key in App-PKI. Each instance is 
immutable and represetns a public key (RSA only for now).

=cut

use Crypt::OpenSSL::CA 0.06;
use App::CamelPKI::Error;
use base "App::CamelPKI::PEM";

sub _marker { "PUBLIC KEY" }

=head1 METHODS

=head2 as_crypt_openssl_ca_publickey()

Returns an instance of 
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::PublicKey> which modelise
the certificate, with a cache.

=cut

sub as_crypt_openssl_ca_publickey {
    my ($self) = @_;
    $self->{cocpk} ||= Crypt::OpenSSL::CA::PublicKey->parse_RSA
        ($self->serialize());
}

=head2 get_modulus()

=head2 get_openssl_keyid()

Perform the same things as the same method in 
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::PublicKey>

=cut

sub get_modulus { shift->as_crypt_openssl_ca_publickey->get_modulus }

sub get_openssl_keyid { shift->as_crypt_openssl_ca_publickey->get_openssl_keyid }

=head2 equals($cert)

Returns true if, and only if, an other object of the same
I<App::CamelPKI::PublicKey> class modelize the same key.

=cut

sub equals {
    my ($self, $other) = @_;
    return ($other->isa(ref($self)) &&
            $self->{der} eq $other->{der});
}


=begin internals

=cut

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Test qw(%test_public_keys);

test "round trip" => sub {
    my $key = $test_public_keys{"rsa1024"};
    is(App::CamelPKI::PublicKey->parse($key)->serialize(), $key,
       "round trip");
};

test "->as_crypt_openssl_ca_publickey" => sub {
    ok(App::CamelPKI::PublicKey->parse($test_public_keys{"rsa1024"})
       ->as_crypt_openssl_ca_publickey
       ->isa("Crypt::OpenSSL::CA::PublicKey"));
};

test "->get_modulus" => sub {
    my $pubkey = App::CamelPKI::PublicKey->parse($test_public_keys{"rsa1024"});
    is($pubkey->get_modulus,
       $pubkey->as_crypt_openssl_ca_publickey->get_modulus);
};

test "->get_openssl_keyid" => sub {
	my $pubkey = App::CamelPKI::PublicKey->parse($test_public_keys{"rsa1024"});
	like($pubkey->get_openssl_keyid, qr/^[0-9A-F:]+$/);
};

test "->equals" => sub {
    my ($pubkey1, $pubkey1too, $pubkey2) = map {
        App::CamelPKI::PublicKey->parse($test_public_keys{$_})
    } (qw(rsa1024 rsa1024 rsa2048));
    ok(! ($pubkey1 == $pubkey1too));
    ok($pubkey1->equals($pubkey1));
    ok($pubkey1->equals($pubkey1too));
    ok($pubkey2->equals($pubkey2));
    ok(! $pubkey1->equals($pubkey2));
};

=end internals

=cut

