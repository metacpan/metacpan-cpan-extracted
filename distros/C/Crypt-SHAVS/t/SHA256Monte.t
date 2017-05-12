BEGIN {
	eval "use Digest::SHA qw(sha256)";
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
Crypt::SHAVS->new(\&sha256)->check($vectors);
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
#  "SHA-256 Monte" information for "sha_values"
#  SHA-256 tests are configured for BYTE oriented implementations
#  Generated on Wed May 11 17:26:03 2011

[L = 32]

Seed = 6d1e72ad03ddeb5de891e572e2396f8da015d899ef0e79503152d6010a3fe691

COUNT = 0
MD = e93c330ae5447738c8aa85d71a6c80f2a58381d05872d26bdd39f1fcd4f2b788

COUNT = 1
MD = 2e78f8c8772ea7c9331d41ed3f9cdf27d8f514a99342ee766ee3b8b0d0b121c0

COUNT = 2
MD = d6a23dff1b7f2eddc1a212f8a218397523a799b07386a30692fd6fe9d2bf0944

COUNT = 3
MD = fb0099a964fad5a88cf12952f2991ce256a4ac3049f3d389c3b9e6c00e585db4
