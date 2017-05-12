use 5.10.1;
use strict;
use warnings;

use Test::More tests=>56;

BEGIN { use_ok( 'Crypt::NSS::X509' ); }

diag('Selfsigned certificate');

{
	my $pem = slurp("certs/selfsigned.crt");
	my $cert = Crypt::NSS::X509::Certificate->new_from_pem($pem);

	isa_ok($cert, 'Crypt::NSS::X509::Certificate');
	is($cert->issuer, 'E=email@domain.invalid,CN=Test Certificate,OU=Test Unit,L=Berkeley,ST=California,C=US', 'issuer');
	is($cert->subject, 'E=email@domain.invalid,CN=Test Certificate,OU=Test Unit,L=Berkeley,ST=California,C=US', 'subject');
	ok($cert->version == 1, 'version == 1');
	is($cert->serial, '009863c9c6d7bd0ee5', 'serial');
	is($cert->notBefore, 'Mon Oct 15 22:23:31 2012', 'notBefore');
	is($cert->notAfter, 'Tue Oct 15 22:23:31 2013', 'notAfter');
	ok(!$cert->subj_alt_name, 'no alt name');
	is($cert->common_name, "Test Certificate", 'Test Certificate');
	is($cert->country_name, "US", 'US');
	is($cert->sig_alg_name, "SHA1WithRSA", 'SHA1WithRSA');
	is($cert->key_alg_name, "RSAEncr", 'RSAEncr');
	ok($cert->bit_length == 1024, 'bit_length == 1024');
	ok($cert->is_root, 'selfsigned');
	is($cert->modulus, 'b1dc1c65ffd421820ed33d720bbdf740ba09bd146fa795a5fcf3249ea9f7eafc338922b0deaadda3a4a8828fee61bf4498e36b3ad07fe24e6168e3ef3f1c1e825f9a61c06df7978c3ea9d77bb8061d03cc07fe1ab732b497a5584363feb539152eb691ba6f9fcfcbc1de9cacfb6b2ccf24e79b0c730c441e5e88b2f3f9764701', 'modulus');
	ok($cert->exponent == 65537, 'exponent');
	is($cert->fingerprint_md5, '69835d74659ad575141f39d1cf8eaa4b', 'md5');
	is($cert->fingerprint_sha1, 'a0d67b4e56e3fbff68e8b8fedd7147119438aa3c', 'sha1');
	is($cert->fingerprint_sha256, 'c9f7b2becca219fb8a170e507d7722064e454a3b569e3677694f64cdf01ca602', 'sha256');
}

diag('Google certificate');
{
	my $pem = slurp("certs/google.crt");
	my $cert = Crypt::NSS::X509::Certificate->new_from_pem($pem, "google");

	isa_ok($cert, 'Crypt::NSS::X509::Certificate');
	is($cert->issuer, 'CN=Thawte SGC CA,O=Thawte Consulting (Pty) Ltd.,C=ZA', 'issuer');
	is($cert->subject, 'CN=www.google.com,O=Google Inc,L=Mountain View,ST=California,C=US', 'subject');
	ok($cert->version == 3, 'version == 3');
	is($cert->serial, '4f9d96d966b0992b54c2957cb4157d4d', 'serial');
	is($cert->notBefore, 'Wed Oct 26 00:00:00 2011', 'notBefore');
	is($cert->notAfter, 'Mon Sep 30 23:59:59 2013', 'notAfter');
	ok(!$cert->subj_alt_name, 'no alt name');
	is($cert->common_name, "www.google.com", 'Test Certificate');
	is($cert->country_name, "US", 'US');
	is($cert->sig_alg_name, "SHA1WithRSA", 'SHA1WithRSA');
	is($cert->key_alg_name, "RSAEncr", 'RSAEncr');
	ok($cert->bit_length == 1024, 'bit_length == 1024');
	ok(!$cert->is_root, 'not selfsigned');
	is($cert->modulus, 'deb72643a69985cd38a71509b9cf0fc9c3558c88ee8c8d2827244b2a5ea0d816fa61184bcf6d6080d335403272c08f12d8e54e8fb9b2f6d9155e5a8631a3ba86aa6bc8d9718ccccd27131e9d425d38f6a7aceffa62f31881d424467f01777cc62a891499bb98391da819fb3900447d1b946a782d69adc07a2cfad0da201298d3', 'modulus');
	ok($cert->exponent == 65537, 'exponent');
	is($cert->fingerprint_md5, '7d7c837f0a8d739d1a1494d0be1f82ea', 'md5');
	is($cert->fingerprint_sha1, 'c1956dc8a7dfb2a5a56934da09778e3a11023358', 'sha1');
	is($cert->fingerprint_sha256, 'ec6a6b156b3062fa99499d1e1515cf6c5048af17945748396bd2ecf12b8de22c', 'sha256');
}

diag('Thawte EC-root certificate');
{
	my $pem = slurp("certs/thawte-ec.crt");
	my $cert = Crypt::NSS::X509::Certificate->new_from_pem($pem);
	
	isa_ok($cert, 'Crypt::NSS::X509::Certificate');
	is($cert->sig_alg_name, "AnsiX962ECDsaSignatureWithSha384", 'AnsiX962ECDsaSignatureWithSha384');
	is($cert->key_alg_name, "ECPublicKey", 'ECPublicKey');
	ok($cert->bit_length == 384, 'bit_length == 384');
	is($cert->country_name, "US", 'US');
	is($cert->modulus, '04a2d59c827b959df1527887fe8a16bf05e6dfa3024f0d07c60051ba0c02522d22a44239c4fe8feac9c1bed44dff9f7a9ee2b17c9aada786097387d1e79ae37aa5aa6efbbab370c06788a235d4a39ab1fdadc2ef31faa8b9f3fb08c691d1fb2995', 'modulus');
	is($cert->curve, 'ECsecp384r1', 'ECsecp384r1');
	is($cert->fingerprint_md5, '749dea6024c4fd22533ecc3a72d9294f', 'md5');
	is($cert->fingerprint_sha1, 'aadbbc22238fc401a127bb38ddf41ddb089ef012', 'sha1');
	is($cert->fingerprint_sha256, 'a4310d50af18a6447190372a86afaf8b951ffb431d837f1e5688b45971ed1557', 'sha256');
}

diag('NIST DSA test-certificate');

{
	my $pem = slurp("certs/nist-dsa.crt");
	my $cert = Crypt::NSS::X509::Certificate->new_from_pem($pem);
	
	isa_ok($cert, 'Crypt::NSS::X509::Certificate');
	is($cert->country_name, "US", 'US');
	is($cert->sig_alg_name, "AnsiX9DsaSignatureWithSha1", 'AnsiX9DsaSignatureWithSha1');
	is($cert->key_alg_name, "AnsiX9DsaSignature", 'AnsiX9DsaSignature');
	ok($cert->bit_length == 1024, 'bit_length == 1024');
	is($cert->modulus, 'b59e1f490447d1dbf53addca0475e8dd75f69b8ab197d6596982d3034dfd3b365f4af2d14ec107f5d12ad378776356ea96614d420b7a1dfbab91a4cedeef77c8e5ef20aea62848afbe69c36aa530f2c2b9d9822b7dd9c4841fde0de854d71b992eb3d088f6d6639ba7e20e82d43b8a681b065631590b49eb99a5d581417bc955', 'modulus');
	is($cert->modulus, $cert->public_key, 'public_key function');
}

sub slurp {
  local $/=undef;
  open (my $file, shift) or die "Couldn't open file: $!";
  my $string = <$file>;
  close $file;
  return $string;
}
