package App::CamelPKI::CertTemplate::CA0;
use strict;
use warnings;
use App::CamelPKI::Time;

=head1 NAME

App::CamelPKI::CertTemplate::CA0 - provide functions to allow
CA0 type certificate generation.

=cut

#use Crypt::OpenSSL::CA;


=head1 Fonctions

This module allows to generate CA0 certificates.

=cut

=head2 prepare_self_signed_certificate

This function aims at generating a root certificate of CA0 type.

=cut

sub prepare_self_signed_certificate {
    my ($class, $cert) = @_;

    my $start_date = App::CamelPKI::Time->now;
    my $end_date = $start_date->advance_years(20);
    $cert->set_notBefore($start_date->zulu);
    $cert->set_notAfter($end_date->zulu);

	    my $dn_subject=Crypt::OpenSSL::CA::X509_NAME->new(
	    	O => "CamelPKI.fr",
			OU => "CamelPKI",
			CN => ".AC racine CamelPKI",
			dnQualifier => $cert->get_public_key->get_openssl_keyid);
		$cert->set_subject_DN($dn_subject);
		$cert->set_issuer_DN($dn_subject);
		$cert->set_extension("basicConstraints",
                                     "CA:TRUE, pathlen:1", -critical => 1);
		$cert->set_extension
                    ("subjectKeyIdentifier",
                     $cert->get_public_key->get_openssl_keyid);
    my $serial = "0x1";
    $cert->set_serial($serial);
    $cert->set_extension("authorityKeyIdentifier" => {
			keyid => $cert->get_public_key->get_openssl_keyid,
			issuer => $dn_subject,
			serial => $serial } );
    $cert->set_extension("keyUsage", "keyCertSign, cRLSign");
}

package App::CamelPKI::CertTemplate::CA1;
use strict;
use warnings;
use base "App::CamelPKI::CertTemplate";


=head1 NAME

App::CamelPKI::CertTemplate::CA1 - provide functions to allow
CA1 type certificate generation.

=head1 Fonctions

This module allows to generate CA1 certificates.

=cut

=head2 prepare_certificate

This function aims at generating a root certificate of CA1 type.

=cut

sub prepare_certificate {
    my ($class, $cacert, $cert, %opts) = @_;

    $cert->set_notBefore(App::CamelPKI::Time->now->zulu);
    $cert->set_notAfter($cacert->get_notAfter);

    my $dn_subject=Crypt::OpenSSL::CA::X509_NAME->new
        (O => "CamelPKI.fr",
         OU => "CamelPKI",
         CN => ".AC operationnelle CamelPKI",
         dnQualifier => $cert->get_public_key->get_openssl_keyid);
    $cert->set_subject_DN($dn_subject);
    $cert->set_extension("basicConstraints", "CA:TRUE, pathlen:0", -critical => 1);
    $cert->set_extension("subjectKeyIdentifier", $cert->get_public_key->get_openssl_keyid);
    $class->copy_from_ca_cert
        ($cacert, $cert, -authoritykeyid_issuer => 1);
    $cert->set_extension("keyUsage", "keyCertSign, cRLSign");
}

require My::Tests::Below unless caller;
1;

__END__

=begin internals

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Test "%test_public_keys", "certificate_chain_ok", "%test_keys_plaintext";
use App::CamelPKI::PrivateKey;
use Crypt::OpenSSL::CA;

my $keysize = 1024;


test "CA0_generate"=> sub {
	my $privKey = App::CamelPKI::PrivateKey->genrsa($keysize)
            ->as_crypt_openssl_ca_privatekey;
	my $certCA0 = Crypt::OpenSSL::CA::X509->new($privKey->get_public_key);
	App::CamelPKI::CertTemplate::CA0->prepare_self_signed_certificate($certCA0);
	my $pem = $certCA0->sign($privKey,"sha256");
	certificate_chain_ok($pem, [$pem]);
};


test "CA1_generate"=> sub {
	my $privKey = App::CamelPKI::PrivateKey->genrsa($keysize)
            ->as_crypt_openssl_ca_privatekey;
	my $certCA0 = Crypt::OpenSSL::CA::X509->new($privKey->get_public_key);
	App::CamelPKI::CertTemplate::CA0->prepare_self_signed_certificate($certCA0);
	my $pemCA0 = $certCA0->sign($privKey,"sha256");
	my $privKeyCA1 = App::CamelPKI::PrivateKey->genrsa($keysize)
            ->as_crypt_openssl_ca_privatekey;
	my $certCA1 = Crypt::OpenSSL::CA::X509->new($privKeyCA1->get_public_key);
	App::CamelPKI::CertTemplate::CA1->prepare_certificate($certCA0, $certCA1);
	my $pemCA1 = $certCA1->sign($privKey,"sha256");	
	certificate_chain_ok($pemCA1, [$pemCA0]);
};

=end internals

=cut
