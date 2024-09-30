use strict;
use warnings;
use Test::More;
use Digest::SHA qw/sha256_hex/;
use Crypt::OpenSSL::Guess qw/openssl_version find_openssl_prefix find_openssl_exec/;

my ($major, $minor, $patch) = openssl_version();
BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };
my $openssl_output =<< 'OPENSSL_END';
MAC: sha1, Iteration 1000
MAC length: 20, salt length: 8
PKCS7 Encrypted data: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 1000
Secret bag
Bag Attributes
    localKeyID: 31 32 33 34 35 36 37 38 39 30 
    1.2.3.4.5: MyCustomAttribute
    friendlyName: george
Bag Type: 1.3.5.7.9
Bag Value: 56 65 72 79 53 65 63 72 65 74 4D 65 73 73 61 67 65 
OPENSSL_END

if ($major eq '1.0') {
  $openssl_output =~ s/MAC: sha1, Iteration 2048/MAC Iteration 2048/g;
  $openssl_output =~ s/MAC length: .*/MAC verified OK/;
}

my $prefix = find_openssl_prefix();
my $ssl_exec = find_openssl_exec($prefix);
my $ssl_version_string = `$ssl_exec version`;

SKIP: {

    skip ("Pre OpenSSL 3.0.0 release secret bags unsupported", 22) if ($major lt '3.0');
    skip ("LibreSSL does not support secret bags", 22) if ($ssl_version_string =~ /LibreSSL/);

my $pass   = "Password1";
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/secretbag.p12');

my $info = $pkcs12->info($pass);

ok(sha256_hex($info) eq sha256_hex($openssl_output), "Output matches OpenSSL");

my $info_hash = $pkcs12->info_as_hash($pass);

if ($major gt '1.0') {
  like($info_hash->{mac}{digest}, qr/sha1/, "MAC Digest is sha1");
  like($info_hash->{mac}{length}, qr/20/, "MAC length is 20");
  like($info_hash->{mac}{salt_length}, qr/8/, "MAC salt_length is 8");
}

like($info_hash->{mac}{iteration}, qr/1000/, "MAC Iteration is 1000");
my $pkcs7_cnt = scalar @{$info_hash->{pkcs7_data}};
ok($info_hash->{pkcs7_data}, "pkcs7_data key exists");

  my $bags = $info_hash->{pkcs7_encrypted_data}[0]->{bags};

  is(scalar @$bags, 1, "One safe_contents_bag in pkcs7_data");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 3, "Three bag attributes in bag");

  like(@$bags[0]->{type}, qr/secret_bag/, "pkcs7_encrypted_data bag type matches");

  $bag_attributes = @$bags[0]->{bag_attributes};
  is(keys %$bag_attributes, 3, "One bag attributes in bag");

  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/31 32 33 34 35 36 37 38 39 30/, "localKeyID matches") if $attribute eq "localKeyID";
        like($bag_attributes->{'1.2.3.4.5'}, qr/MyCustomAttribute/, "1.2.3.4.5 matches") if $attribute eq "1.2.3.4.5";
        like($bag_attributes->{friendlyName}, qr/george/, "friendlyName matches") if $attribute eq "friendlyName";
  }
}

done_testing;
