#!perl -w

package App::CamelPKI::Certificate;
use strict;

=head1 NAME

B<App::CamelPKI::Certificate> - Model for a X509 certificate in Camel-PKI.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use App::CamelPKI::Certificate;

  my $cert = parse App::CamelPKI::Certificate($pemstring, -format => "PEM");

  print $cert->get_serial;

  my $derstring = $cert->serialize(-format => "DER");

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

This class is a L<Crypt::X509> and L<Convert::ASN1> I<wrapper>; Its
compensate these two packages deficiencies and provide a complete
abstraction for X509 certificates, no matter they were issued by
Camel-PKI or not.

Each instance of this classe represents a certificate. Instances are
immutable.

=cut

use Crypt::X509;
use Crypt::OpenSSL::CA 0.05;
use App::CamelPKI::PublicKey;
use NEXT;
use base "App::CamelPKI::PEM";

sub _marker { "CERTIFICATE" }

=head1 METHODS

=head2 parse($texte, %options)

=head2 load($file, %options)

=head2 serialize(%options)

These methods are inherited from L<App::CamelPKI::PEM>.

=head2 parse_bundle($texte)

Load $texte, which is a certificate I<bundle>, ie a concatenation of
one or more certificates in PEM format. Returns a list of 
I<App::CamelPKI::Certificate> objects.

=cut

sub parse_bundle {
    my ($class, $text) = @_;

    throw App::CamelPKI::Error::Internal("MUST_CALL_IN_LIST_CONTEXT")
        if (! wantarray);

    my @allcerts = $text =~
        m/(-+BEGIN.*?-+$
          .*?
          ^-+END.*?-+$)/gmsx;
    return map { scalar $class->parse($_) }
        @allcerts;
}

=head2 as_crypt_openssl_ca_x509()

Returns an intance of L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::X509>
which modelize the certificate. This instance is newly created for
each call, so that I<App::CamelPKI::Certificate> do not have a shared
mutable state.

=cut

sub as_crypt_openssl_ca_x509 {
    my ($self) = @_;
    Crypt::OpenSSL::CA::X509->parse($self->serialize());
}


=head2 get_serial

=head2 get_issuer_DN

=head2 get_subject_DN

=head2 get_subject_keyid

=head2 get_notBefore

=head2 get_notAfter

Delegated to methods of the same name in
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::X509>.

=cut

sub get_serial        { shift->_as_x509_cached->get_serial }
sub get_subject_DN    { shift->_as_x509_cached->get_subject_DN }
sub get_issuer_DN     { shift->_as_x509_cached->get_issuer_DN }
sub get_subject_keyid { shift->_as_x509_cached->get_subject_keyid }
sub get_notBefore     { shift->_as_x509_cached->get_notBefore }
sub get_notAfter      { shift->_as_x509_cached->get_notAfter }

=head2 get_subject_CN

Returns the CN of the DN of the certificate suject.

=cut

sub get_subject_CN {
    my ($self) = @_;
    Crypt::X509->new( cert => $self->serialize(-format => "DER") )
        ->subject_cn;
}

=head2 get_public_key

Returns an object of the L<App::CamelPKI::PublicKey> class.

=cut

sub get_public_key {
    my ($self) = @_;
    App::CamelPKI::PublicKey->parse
        ($self->_as_x509_cached->get_public_key->to_PEM);
}

=head2 equals($cert)

Returns true only if $cert, another object of the same 
I<App::CamelPKI::Certificate> classe, modelise the same certificate.

=cut

sub equals {
    my ($self, $other) = @_;
    return ($other->isa(ref($self)) &&
            $self->{der} eq $other->{der});
}

=begin internals

=head2 _as_x509_cached()

As L</as_crypt_openssl_ca_x509>, but using cache. This method is private
because, the returned object being mutable, it must not be shared under
penalty of creating a subliminal canal between owners of a reference on the
same I<App::CamelPKI::Certificate> object.

=cut

sub _as_x509_cached {
    my ($self) = @_;
    $self->{cocx} ||= $self->as_crypt_openssl_ca_x509;
}


require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use File::Slurp;
use App::CamelPKI::Error;
use JSON;

my $certificate = <<"CERTIFICATE";
-----BEGIN CERTIFICATE-----
MIICsDCCAhmgAwIBAgIJANdqtXzdPS/1MA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMDcwMTMxMTcwNjU5WhcNMzcwMTMxMTcwNjU5WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZD6L+Dn8MZd69PuXc
ZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+XyppA8fZx6bnuHKUa
bqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwIDAQABo4GnMIGkMB0G
A1UdDgQWBBTu+qGX79xcvFE8pG5zx2FcqAuV5TB1BgNVHSMEbjBsgBTu+qGX79xc
vFE8pG5zx2FcqAuV5aFJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt
U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJANdqtXzd
PS/1MAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEACQ+4e3MSlcqkhzgZ
rTXpsO/WpBT7aaM7AaecY54hB9uF9PmGC1q3axwZ2b/+Gh5ehQPyAwKevyjNz1y4
yP4YeUHO6FIHd0RyGEnM3cqcoqg8TewXlUwOkHphCrZ5eFbxxEarVz1wwkZqd5z0
3IInE3EJ7D8rxfbC1c1fdeh8akI=
-----END CERTIFICATE-----
CERTIFICATE

test "round trip" => sub {
    is(App::CamelPKI::Certificate->parse($certificate)->serialize(),
       $certificate, "round trip");
};

test "->parse() with bad arguments" => sub {
    try {
        App::CamelPKI::Certificate->parse();
        fail;
    } catch App::CamelPKI::Error::Internal with {
        pass;
    };

    try {
        App::CamelPKI::Certificate->parse(undef);
        fail;
    } catch App::CamelPKI::Error::Internal with {
        pass;
    };

	#TODO: verifier pourquoi ca marche pas
#    try {
#        App::CamelPKI::Certificate->parse(JSON::from_json("null"));
#        fail;
#    } catch App::CamelPKI::Error::Internal with {
#        pass;
#    };
};

use App::CamelPKI::Test qw(%test_entity_certs %test_public_keys
                      %test_rootca_certs
                     certificate_chain_ok);
test "equals" => sub {
    my ($cert1, $cert1too, $cert2) = map {
        App::CamelPKI::Certificate->parse($test_entity_certs{$_})
    } (qw(rsa1024 rsa1024 rsa2048));
    ok(! ($cert1 == $cert1too));
    ok($cert1->equals($cert1));
    ok($cert1->equals($cert1too));
    ok($cert2->equals($cert2));
    ok(! $cert1->equals($cert2));
};

test "load" => sub {
	my $tmpCert = My::Tests::Below->tempdir."/certtemp";
	write_file($tmpCert, $certificate);
	my $cert = App::CamelPKI::Certificate->load($tmpCert);
	ok($cert->isa('App::CamelPKI::Certificate'));
};

test "->get_public_key" => sub {
    my $cert = App::CamelPKI::Certificate->parse($test_entity_certs{rsa1024});
    my $pubkey = $cert->get_public_key();
    ok($pubkey->isa("App::CamelPKI::PublicKey"));
    is($pubkey->serialize(), $test_public_keys{rsa1024});
};


test "->get_subject_CN" => sub {
    my $cert = App::CamelPKI::Certificate->parse($test_entity_certs{rsa1024});
    is($cert->get_subject_CN, "John Doe");
};

test "REGRESSION: ->serialize() on a piece of PEM which match "
    . "an exact number of lines" => sub {
        my $der = MIME::Base64::decode_base64(<<"CERT");
MIIEGjCCAwKgAwIBAgIBEjANBgkqhkiG9w0BAQsFADCBuTEeMBwGA1UEChMVRWNs
YWlyIERpZ2l0YWwgQ2luZW1hMR4wHAYDVQQLExVFY2xhaXIgRGlnaXRhbCBDaW5l
bWExMTAvBgNVBAMTKC5BQyBvcGVyYXRpb25uZWxsZSBFY2xhaXIgRGlnaXRhbCBD
aW5lbWExRDBCBgNVBC4TOzgyOjk1OjgyOkE2OjBCOjE4OkQwOkM4OjhFOjZFOkZB
OjkwOkY5OkQ4OkQ5OjIwOjMzOkY2OjQ4Ojc4MB4XDTA3MDMyMTE2NDA0OFoXDTM3
MDMyMTE2MzkwMFowWDEfMB0GA1UECgwWRWNsYWlyRGlnaXRhbENpbmVtYS5mcjEQ
MA4GA1UECwwHV0FOIEVEQzEMMAoGA1UECwwDVlBOMRUwEwYDVQQDDAxtb25zaXRl
Mi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCh/Y1Egj7uF+rp
hGe2I8TQ8o1aXQFfrrwzxfZGXxhRiiuF0sjxT0snjNdaevnh1ksIIniOiYRKHoZq
hyYyPBUdingCznyWAqvOgx/0kombATRtPOMEi9u0p37mo7PuQBqY3YC7s64xo50r
wf1Mqkz7hriNOwnOS0Ed0W4uKlgIzJlVJ8YbT+33SO43bWVMhqHzUYOHDSv4RRmw
H9vYp+bBXHuUiaqYX+EVtUD9MYjUHPl7Q0GMQdUQRIy4D9m4pbA2zXMmViu3+GbB
XC1V/oYQa5DvJJMOLNKbORwns9Kh8nYTcTiGypm3JsLEXly/n1gUHyucMb0Mr/t2
sGcM2yx3AgMBAAGjgYwwgYkwHwYDVR0jBBgwFoAUgpWCpgsY0MiObvqQ+djZIDP2
SHgwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU9HHTeTY+jbyeGljLQwAwLAU+DDMw
CwYDVR0PBAQDAgUgMBcGA1UdEQQQMA6CDG1vbnNpdGUyLmNvbTATBgNVHSUEDDAK
BggrBgEFBQcDAjANBgkqhkiG9w0BAQsFAAOCAQEADuI5g6Zawq+xbX2oYBE5+Ao1
0ewhWRd9vhSgecO3ZAAf1BYOWqu4908vOHMjPgYhhWBhQEg6rLm6SLLW0KRinrKO
hnhAC23ZQIw4SopdCduj29XUYhdM4kPBZL3dFjb2T7HIv/ryMOzBgbNATJ/XCUSs
SRhLssYn+M2aulxU5qWBwTZfUfiXYQ0jMYJDzEbTr9Trg+02aqge/Cyln0FytZAN
HGDKZ/soQ6Sp0/+zlyrrM56UYr2eTHFMJ/RAlrYm/PGY7QRZZWI/eatY0VM6UOL5
TKd9GkPVZQqhI5fSziMr4gaO4MfgZ39Dp5JDk0V8VCO7TdQ8mB1pBTMfAo+rZA==
CERT

        App::CamelPKI::Certificate->parse($der, -format => "DER")
            ->get_serial;
        pass;
};

test "->parse_bundle()" => sub {
    my @certs = App::CamelPKI::Certificate->parse_bundle
   	($test_rootca_certs{rsa1024} . $test_entity_certs{rsa1024});
    is(scalar(@certs), 2);
    my ($cert0, $cert1) = @certs;
    certificate_chain_ok($cert1->serialize, [$cert0->serialize]);
};

=end internals

=cut
