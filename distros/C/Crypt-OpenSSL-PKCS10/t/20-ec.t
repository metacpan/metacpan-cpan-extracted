use strict;
use warnings;
use Test::Lib;
use Test::Crypt::OpenSSL::PKCS10;
use Test::More tests => 19;

BEGIN { use_ok('Crypt::OpenSSL::PKCS10') };

{
my $req_ecc_pem = Crypt::OpenSSL::PKCS10->new_from_file("t/csrs/ecc.csr");
like($req_ecc_pem->subject(), qr/C=CA, ST=New Brunswick, L=Moncton, O=Crypt::OpenSSL::PKCS10, CN=Crypt::OpenSSL::PKCS10/, "Read Subject from ecc.csr (ECC PEM)");
# FIXME: this should work but some openssl are not outputing the modulus the same way
#like($req_ecc_pem->keyinfo(), qr/c1:11:0d:ff:85:e6:76:7/m, "Read Key Info from ecc.csr (ECC PEM)");
like($req_ecc_pem->pubkey_type(), qr/ec/, "Read public key type from ecc.csr (ECC PEM)");
like($req_ecc_pem->get_pem_pubkey(), qr/j0CAQYIKoZIzj0DAQcDQgAEtSMNAzCSKt/m, "Read PEM public key from ecc.csr (ECC PEM)");
ok($req_ecc_pem);
}

{
my $req_new_ecc_pem = Crypt::OpenSSL::PKCS10->new({ type => "ec" });
$req_new_ecc_pem->set_subject("/C=CA/O=Crypt::OpenSSL::PKCS10/OU=Perl module");
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_key_usage,"critical,digitalSignature,keyEncipherment");
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_ext_key_usage,"serverAuth, nsSGC, msSGC, 1.3.4");
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,'email:timlegge@gmail.com');
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_key_identifier, "hash");
$req_new_ecc_pem->add_custom_ext('1.3.4.5.1',"My new extension");
$req_new_ecc_pem->add_custom_ext_raw('1.2.3.4', pack('H*','1E06006100620063'));
$req_new_ecc_pem->add_ext_final();
$req_new_ecc_pem->sign();
ok ($req_new_ecc_pem, "Successfully created EC based CSR");

my $output = get_openssl_output($req_new_ecc_pem->get_pem_req());

like($output, qr/ASN1 OID: secp384r1/, "ASN1 OID: ssecp384r1");
like($output, qr/X509v3 Key Usage: critical/, "X509v3 Key Usage: critical");
like($output, qr/Digital Signature, Key Encipherment/, "Digital Signature, Key Encipherment");
like($output, qr/Subject.*Crypt::OpenSSL::PKCS10.*Perl module/, "Subject matched");
like($output, qr/TLS Web Server Authentication, Netscape Server Gated Crypto, Microsoft Server Gated Crypto, 1.3.4/, "NID_key_usage");
like($output, qr/email:timlegge\@gmail.com/, "email matched");
}


{
my $req_new_ecc_pem = Crypt::OpenSSL::PKCS10->new({ type => "ec", curve => 'secp112r1', hash => 'SHA256' });
$req_new_ecc_pem->set_subject("/C=CA/O=Crypt::OpenSSL::PKCS10/OU=Perl module");
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_key_usage,"critical,digitalSignature,keyEncipherment");
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_ext_key_usage,"serverAuth, nsSGC, msSGC, 1.3.4");
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,'email:timlegge@gmail.com');
$req_new_ecc_pem->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_key_identifier, "hash");
$req_new_ecc_pem->add_ext_final();
$req_new_ecc_pem->sign('SHA256');
ok ($req_new_ecc_pem, "Successfully created EC based CSR");

my $output = get_openssl_output($req_new_ecc_pem->get_pem_req());

like($output, qr/ASN1 OID: secp112r1/, "ASN1 OID: secp112r1");
like($output, qr/X509v3 Key Usage: critical/, "X509v3 Key Usage: critical");
like($output, qr/Digital Signature, Key Encipherment/, "Digital Signature, Key Encipherment");
like($output, qr/Subject.*Crypt::OpenSSL::PKCS10.*Perl module/, "Subject matched");
like($output, qr/TLS Web Server Authentication, Netscape Server Gated Crypto, Microsoft Server Gated Crypto, 1.3.4/, "NID_key_usage");
like($output, qr/email:timlegge\@gmail.com/, "email matched");
}

