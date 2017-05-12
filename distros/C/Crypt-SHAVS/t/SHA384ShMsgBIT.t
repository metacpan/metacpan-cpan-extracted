BEGIN {
	eval "use Digest::SHA";
	if ($@) {
		print "1..0 # Skipped: Digest::SHA not installed\n";
		exit;
	}
}

use strict;
use FileHandle;
use Crypt::SHAVS;

my $sha384BIT = sub {Digest::SHA->new(384)->add_bits($_[0], $_[1])->digest};

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new($sha384BIT, 1)->check($vectors);
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
#  CAVS 11.0
#  "SHA-384 ShortMsg" information 
#  SHA-384 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:14 2011

[L = 48]

Len = 0
Msg = 00
MD = 38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b

Len = 1
Msg = 00
MD = 634aa63038a164ae6c7d48b319f2aca0a107908e548519204c6d72dbeac0fdc3c9246674f98e8fd30221ba986e737d61

Len = 2
Msg = 00
MD = c6b08368812f4f02aaf84c1b8fcd549f53099816b212fe68cb32f6d73563fae8cec52b96051ade12ba8f3c6a6e98a616

Len = 3
Msg = e0
MD = 1d215d63deceaa2ff2a0851ffc233c98d09edff13f23e664b59c53abf500694cf5813a0e96b3c98fdb4ffa7e39f564d4
