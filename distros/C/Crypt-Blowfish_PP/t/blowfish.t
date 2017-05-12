print "1..5\n";

use Crypt::Blowfish_PP;

my $blowfish=new Crypt::Blowfish_PP(pack("H*","0000000000000000"));
print "not " if(!defined($blowfish));
print "ok 1\n";

my $data;
my $out;

$data=pack("H*","0000000000000000");
$out=$blowfish->encrypt($data);
print "not " if(uc(unpack("H16",$out)) ne "4EF997456198DD78");
print "ok 2\n";
$data=$blowfish->decrypt($out);
print "not " if(uc(unpack("H*",$data)) ne "0000000000000000");
print "ok 3\n";

$data=pack("H*","FFFFFFFFFFFFFFFF");
$out=$blowfish->encrypt($data);
print "not " if(uc(unpack("H16",$out)) ne "014933E0CDAFF6E4");
print "ok 4\n";
$data=$blowfish->decrypt($out);
print "not " if(uc(unpack("H*",$data)) ne "FFFFFFFFFFFFFFFF");
print "ok 5\n";

