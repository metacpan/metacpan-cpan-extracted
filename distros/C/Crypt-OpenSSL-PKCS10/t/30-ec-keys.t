use strict;
use warnings;
use Test::More tests => 628;
use Test::Lib;
use Test::Crypt::OpenSSL::PKCS10;

BEGIN { use_ok('Crypt::OpenSSL::PKCS10') };

my @hashs = qw/SHA1 SHA224 SHA256 SHA512/;
my @curves = qw/secp112r2 secp128r1 secp128r2 secp160k1 secp160r1   secp160r2   secp192k1   secp224k1   secp224r1   secp256k1   secp384r1   secp521r1   prime192v1  prime192v2  prime192v3  prime239v1  prime239v2  prime239v3  prime256v1  sect113r1   sect113r2   sect131r1   sect131r2   sect163k1   sect163r1   sect163r2   sect193r1   sect193r2   sect233k1   sect233r1   sect239k1   sect283k1   sect283r1   sect409k1   sect409r1   sect571k1   sect571r1   c2pnb163v1  c2pnb163v2  c2pnb163v3  c2pnb176v1  c2tnb191v1  c2tnb191v2  c2tnb191v3  c2pnb208w1  c2tnb239v1  c2tnb239v2  c2tnb239v3  c2pnb272w1  c2pnb304w1  c2tnb359v1  c2pnb368w1  c2tnb431r1  wap-wsg-idm-ecid-wtls1  wap-wsg-idm-ecid-wtls3  wap-wsg-idm-ecid-wtls4  wap-wsg-idm-ecid-wtls5  wap-wsg-idm-ecid-wtls6  wap-wsg-idm-ecid-wtls7  wap-wsg-idm-ecid-wtls8  wap-wsg-idm-ecid-wtls9  wap-wsg-idm-ecid-wtls10  wap-wsg-idm-ecid-wtls11  wap-wsg-idm-ecid-wtls12  brainpoolP160r1  brainpoolP160t1  brainpoolP192r1  brainpoolP192t1  brainpoolP224r1  brainpoolP224t1  brainpoolP256r1  brainpoolP256t1  brainpoolP320r1  brainpoolP320t1  brainpoolP384r1  brainpoolP384t1  brainpoolP512r1  brainpoolP512t1/;

#diag("Only hash passed should default to 1024"); 
foreach my $hash (@hashs) {
    foreach my $curve (@curves) {
        my $req = Crypt::OpenSSL::PKCS10->new({type => 'ec', curve => $curve, hash => $hash});
        my $output = get_openssl_output($req->get_pem_req());
        my $hash_re = 'ecdsa-with-' . $hash;
        like($output, qr/$hash_re/, "Digest $hash matches");
        my $curve_re = "ASN1 OID: " . $curve;
        like($output, qr/$curve_re/, "Digest $curve matches");
    }
}

#diag("Invalid curve cannot create a key"); 
{
    my $req;
    eval {
         $req = Crypt::OpenSSL::PKCS10->new({type => 'ec', curve => 'sect112r1'});
    };
    like ($@, qr/unknown curve name \(sect112r1\)|ec key for sect112r1/, "Invalid curve cannot create a key");
}

#diag("Too many arguements passed"); 
{
    eval {
        my $req = Crypt::OpenSSL::PKCS10->new(1024, {type => 'ec', hash => 'SHA256'}, 'Too Many');
    };
    like ($@, qr/Maximum 2 optional arguements/, "Correctly errors on too many arguements");
}

#diag("keysize and hash passed in wrong order"); 
{
    eval {
        my $req = Crypt::OpenSSL::PKCS10->new({type => 'ec', hash => 'SHA256'}, 1024);
    };
    like ($@, qr/Wrong order for arguements/, "Correctly errors on wrong order for arguements");
}

done_testing;
