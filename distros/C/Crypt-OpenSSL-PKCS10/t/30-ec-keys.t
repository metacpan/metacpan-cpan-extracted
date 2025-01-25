use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::Crypt::OpenSSL::PKCS10;

BEGIN { use_ok('Crypt::OpenSSL::PKCS10') };

my @hashs = qw/SHA384 SHA256 SHA512/;
my @curves = qw/secp224r1 secp256k1 secp384r1 secp521r1 prime256v1 /;

my @extra_curves = qw/brainpoolP256r1  brainpoolP256t1  brainpoolP320r1  brainpoolP320t1  brainpoolP384r1  brainpoolP384t1  brainpoolP512r1  brainpoolP512t1/;

my ($major, $minor, $patch) = openssl_version();
print "$major. $minor\n";
my @all_curves = (@curves, ($major ne 1 && $minor lt 2) ? (): @extra_curves);

#diag("Only hash passed should default to 1024"); 
foreach my $hash (@hashs) {
    foreach my $curve (@all_curves) {
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

