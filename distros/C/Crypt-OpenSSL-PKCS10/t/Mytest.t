# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mytest.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 21;
BEGIN { use_ok('Crypt::OpenSSL::PKCS10') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
my $req = Crypt::OpenSSL::PKCS10->new();
print STDERR $req->get_pem_req();
print STDERR $req->get_pem_pk(), "\n";
print STDERR $req->subject()."\n";
print STDERR $req->keyinfo()."\n";
ok($req, "RSA signed CSR default options");
}

use_ok('Crypt::OpenSSL::RSA');

{
my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);
my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($rsa);
print STDERR $req->get_pem_req();
print STDERR $req->subject()."\n";
print STDERR $req->keyinfo()."\n";
print STDERR $req->pubkey_type()."\n";
print STDERR $req->get_pem_pubkey()."\n";
ok($req, "new_from_rsa and defaulr SHA256 with 1024 keylen");
}

{
my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);
my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($rsa, {type => 'rsa', hash => 'SHA384'});
print STDERR $req->get_pem_req();
print STDERR $req->subject()."\n";
print STDERR $req->keyinfo()."\n";
print STDERR $req->pubkey_type()."\n";
print STDERR $req->get_pem_pubkey()."\n";
ok($req, "new_from_rsa with SHA384 hash");
}
{
my $req = Crypt::OpenSSL::PKCS10->new();
$req->set_subject("/C=RO/O=UTI/OU=ssi");
$req->add_ext(Crypt::OpenSSL::PKCS10::NID_key_usage,"critical,digitalSignature,keyEncipherment");
$req->add_ext(Crypt::OpenSSL::PKCS10::NID_ext_key_usage,"serverAuth, nsSGC, msSGC, 1.3.4");
$req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,'email:steve@openssl.org');
$req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_key_identifier, "hash");
$req->add_custom_ext('1.2.3.3',"My new extension");
$req->add_custom_ext_raw('1.2.3.4', pack('H*','1E06006100620063'));
$req->add_ext_final();
$req->sign();
print STDERR $req->get_pem_req();
print STDERR $req->keyinfo()."\n";
print STDERR $req->get_pem_pubkey()."\n";
like($req->subject(), qr/C=RO, O=UTI, OU=ssi/, "Read Subject from new PKCS10");
like($req->pubkey_type(), qr/rsa/, "Read public key type from new PKCS10");
ok($req);
}

{
my $req_2 = Crypt::OpenSSL::PKCS10->new_from_file("t/csrs/CSR.csr");
like($req_2->subject(), qr/C=DE, ST=NRW, L=Foo, O=Internet Widgits Pty Ltd, CN=foo.der.bar.com/, "Read Subject from CSR.csr");
#like($req_2->keyinfo(), qr/47:b0:60:58:46:3e:68:46/m, "Read Key Info from CSR.csr");
like($req_2->pubkey_type(), qr/rsa/, "Read public key type from CSR.csr");
like($req_2->get_pem_pubkey(), qr/cIPeHtJryFNmaGZJWNZW7AvlriVtKigGEFtT9G7PqSw2h8/m, "Read PEM public key from CSR.csr");
ok($req_2);
}

{
my $req_csr = Crypt::OpenSSL::PKCS10->new_from_file("t/csrs/CSR.csr", Crypt::OpenSSL::PKCS10::FORMAT_PEM());
like($req_csr->subject(), qr/C=DE, ST=NRW, L=Foo, O=Internet Widgits Pty Ltd, CN=foo.der.bar.com/, "Read Subject from CSR.csr (PEM)");
#like($req_csr->keyinfo(), qr/47:b0:60:58:46:3e:68:46/m, "Read Key Info from CSR.csr (PEM)");
like($req_csr->pubkey_type(), qr/rsa/, "Read public key type from CSR.csr (PEM)");
like($req_csr->get_pem_pubkey(), qr/cIPeHtJryFNmaGZJWNZW7AvlriVtKigGEFtT9G7PqSw2h8/m, "Read PEM public key from CSR.csr (PEM)");
ok($req_csr);
}

{
my $req_der = Crypt::OpenSSL::PKCS10->new_from_file("t/csrs/CSR.der", Crypt::OpenSSL::PKCS10::FORMAT_ASN1());
like($req_der->subject(), qr/C=DE, ST=NRW, L=Foo, O=Internet Widgits Pty Ltd, CN=foo.der.bar.com/, "Read Subject from CSR.der (DER)");
#like($req_der->keyinfo(), qr/47:b0:60:58:46:3e:68:46/m, "Read Key Info from CSR.der (DER)");
like($req_der->pubkey_type(), qr/rsa/, "Read public key type from CSR.der (DER)");
like($req_der->get_pem_pubkey(), qr/cIPeHtJryFNmaGZJWNZW7AvlriVtKigGEFtT9G7PqSw2h8/m, "Read PEM public key from CSR.der (DER)");
ok($req_der);
}

{
eval {
	Crypt::OpenSSL::PKCS10->new_from_file("file_doesnt_exist");
};
like($@, qr{^Cannot open file 'file_doesnt_exist'}, "Check error if file doesn't exist.");
}
