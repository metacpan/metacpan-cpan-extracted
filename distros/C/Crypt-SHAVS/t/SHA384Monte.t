BEGIN {
	eval "use Digest::SHA qw(sha384)";
	if ($@) {
		print "1..0 # Skipped: Digest::SHA not installed\n";
		exit;
	}
}

use strict;
use FileHandle;
use Crypt::SHAVS;

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new(\&sha384)->check($vectors);
select($stdout);

my $testnum = 1;
print "1..$numtests\n";
$fh->seek(0, 0);
while (<$fh>) {
	print "not " unless /OK\s*$/;
	print "ok ", $testnum++, "\n";
}
close($fh);

__DATA__
#  CAVS 11.1
#  "SHA-384 Monte" information for "sha_values"
#  SHA-384 tests are configured for BYTE oriented implementations
#  Generated on Wed May 11 17:26:04 2011

[L = 48]

Seed = edff07255c71b54a9beae52cdfa083569a08be89949cbba73ddc8acf429359ca5e5be7a673633ca0d9709848f522a9df

COUNT = 0
MD = e81b86c49a38feddfd185f71ca7da6732a053ed4a2640d52d27f53f9f76422650b0e93645301ac99f8295d6f820f1035

COUNT = 1
MD = 1d6bd21713bffd50946a10c39a7742d740e8f271f0c8f643d4c95375094fd9bf29d89ee61a76053f22e44a4b058a64ed

COUNT = 2
MD = 425167b66ae965bd7d68515b54ebfa16f33d2bdb2147a4eac515a75224cd19cea564d692017d2a1c41c1a3f68bb5a209

COUNT = 3
MD = 9e7477ffd4baad1fcca035f4687b35ed47a57832fb27d131eb8018fcb41edf4d5e25874466d2e2d61ae3accdfc7aa364
