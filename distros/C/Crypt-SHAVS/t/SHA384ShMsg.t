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
#  CAVS 11.0
#  "SHA-384 ShortMsg" information 
#  SHA-384 tests are configured for BYTE oriented implementations
#  Generated on Tue Mar 15 08:23:39 2011

[L = 48]

Len = 0
Msg = 00
MD = 38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b

Len = 8
Msg = c5
MD = b52b72da75d0666379e20f9b4a79c33a329a01f06a2fb7865c9062a28c1de860ba432edfd86b4cb1cb8a75b46076e3b1

Len = 16
Msg = 6ece
MD = 53d4773da50d8be4145d8f3a7098ff3691a554a29ae6f652cc7121eb8bc96fd2210e06ae2fa2a36c4b3b3497341e70f0

Len = 24
Msg = 1fa4d5
MD = e4ca4663dff189541cd026dcc056626419028774666f5b379b99f4887c7237bdbd3bea46d5388be0efc2d4b7989ab2c4
