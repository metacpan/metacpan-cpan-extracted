BEGIN {
	eval "use Digest::SHA qw(sha512)";
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
Crypt::SHAVS->new(\&sha512)->check($vectors);
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
#  "SHA-512 Monte" information for "sha_values"
#  SHA-512 tests are configured for BYTE oriented implementations
#  Generated on Wed May 11 17:26:11 2011

[L = 64]

Seed = 5c337de5caf35d18ed90b5cddfce001ca1b8ee8602f367e7c24ccca6f893802fb1aca7a3dae32dcd60800a59959bc540d63237876b799229ae71a2526fbc52cd

COUNT = 0
MD = ada69add0071b794463c8806a177326735fa624b68ab7bcab2388b9276c036e4eaaff87333e83c81c0bca0359d4aeebcbcfd314c0630e0c2af68c1fb19cc470e

COUNT = 1
MD = ef219b37c24ae507a2b2b26d1add51b31fb5327eb8c3b19b882fe38049433dbeccd63b3d5b99ba2398920bcefb8aca98cd28a1ee5d2aaf139ce58a15d71b06b4

COUNT = 2
MD = c3d5087a62db0e5c6f5755c417f69037308cbce0e54519ea5be8171496cc6d18023ba15768153cfd74c7e7dc103227e9eed4b0f82233362b2a7b1a2cbcda9daf

COUNT = 3
MD = bb3a58f71148116e377505461d65d6c89906481fedfbcfe481b7aa8ceb977d252b3fe21bfff6e7fbf7575ceecf5936bd635e1cf52698c36ef6908ddbd5b6ae05
