BEGIN {
	eval "use Digest::SHA qw(sha1)";
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
Crypt::SHAVS->new(\&sha1)->check($vectors);
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
#  "SHA-1 Monte" information for "sha_values"
#  SHA tests are configured for BYTE oriented implementations
#  Generated on Wed May 11 17:26:02 2011

[L = 20]

Seed = dd4df644eaf3d85bace2b21accaa22b28821f5cd

COUNT = 0
MD = 11f5c38b4479d4ad55cb69fadf62de0b036d5163

COUNT = 1
MD = 5c26de848c21586bec36995809cb02d3677423d9

COUNT = 2
MD = 453b5fcf263d01c891d7897d4013990f7c1fb0ab

COUNT = 3
MD = 36d0273ae363f992bbc313aa4ff602e95c207be3
