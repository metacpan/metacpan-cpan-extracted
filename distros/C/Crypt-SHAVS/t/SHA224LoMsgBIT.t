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

my $sha224BIT = sub {Digest::SHA->new(224)->add_bits($_[0], $_[1])->digest};

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new($sha224BIT, 1)->check($vectors);
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
#  "SHA-224 LongMsg" information 
#  SHA-224 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:09 2011

[L = 28]

Len = 611
Msg = fb7374a61f74633e66b0c230a8eb4c1997606894f41bfebb03a48aeb3cdd6fc8432d8d811ade155696c49c570f206f6e5cc3279ffe777d8f9c9a5f43b00c432b7f4cbb5f4edd4928d3ef75c2e0
MD = c3380d1c0abbd61b9c0f1704f4270b1314726144ccc3ad042dd082d7

Len = 710
Msg = e419ffb0a2292d4aa2006b89424d3b2f4792a96e30283908c4841eb5eeb8acc5ca3c100600ef3fe851592cdf6f333e091229011148de1c530c3183411bbfed0503a889687d97ecf2fcfc4e52869cf701c34cf42354f90eae64
MD = 1a1c8a1a20550805fdb261a6539c9b7c083984f4c1ed723bb8a69a0d

Len = 809
Msg = 746cec667a680efef569f0e4e01101d9c945df15d42578dd02416f58b309c19f6a86a813d148bff3fda0672ef20f6a756afddf95d2ae4e04967314b99e1d084119b75e107975cc15bee7ec91f872e22807013e39a6f8246ba86aaa88808b818f0768d8047a80
MD = 5034aee6889f3fc0cb654694a9b511f258dbcaa173e6dbfac71f3701

Len = 908
Msg = b6ce7d00731184b24428df046b9ff688bf417cfaa137ff7d3274bd27c450bac08e720fc7a3f485b625c26288b54383772f3cab0a94f11b4f488d63657ec3773ef0b605a3d31606790a8c94429a59fbe75e3a12b4fc8ecca417ba0adfc6cdb3814560079debc130825c501a3c0028855eb400
MD = 78c6a2abb09309e8e4043dc020345da4b034fe84be669575c3c7474c
