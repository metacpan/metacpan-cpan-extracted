print "1..3\n";

use Crypt::OpenSSL::Blowfish;

my $cipher = new Crypt::OpenSSL::Blowfish(pack("H*", "0123456789ABCDEF"));
print "not " unless defined $cipher;
print "ok 1\n";

my $data = pack("H*", "0000000000000000");

my $out = $cipher->encrypt($data);
print "not " if(uc(unpack("H16", $out)) ne "884659249A365457");
print "ok 2\n";

$data = $cipher->decrypt($out);
print "not " if(uc(unpack("H*", $data)) ne "0000000000000000");
print "ok 3\n";
