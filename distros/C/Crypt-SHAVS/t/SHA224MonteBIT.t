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
#  CAVS 11.1
#  "SHA-224 Monte" information for "sha_values"
#  SHA-224 tests are configured for BIT oriented implementations
#  Generated on Wed May 11 16:55:59 2011

[L = 28]

Seed = 3d4cd83b6b83355ca34fb473de56b5721d27d984ab6f67e6a36feff8

COUNT = 0
MD = 175e8cec3041b5f5ab011ddf00f39f97f3902e636a75d03eadf2bfa6

COUNT = 1
MD = 6d920de35c8675af47fac23b379110fd20951e7af97252d46bedf805

COUNT = 2
MD = c237dbef3e3195b7fd0d055b82cffe5b9769284db9f643abb9263c9d

COUNT = 3
MD = b97ef8ca0e04732f6bc56c1d5d0f5313c3491a27157ca33498acfa9a
