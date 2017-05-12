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
#  CAVS 11.0
#  "SHA-1 ShortMsg" information
#  SHA-1 tests are configured for BYTE oriented implementations
#  Generated on Tue Mar 15 08:23:35 2011

[L = 20]

Len = 0
Msg = 00
MD = da39a3ee5e6b4b0d3255bfef95601890afd80709

Len = 8
Msg = 36
MD = c1dfd96eea8cc2b62785275bca38ac261256e278

Len = 16
Msg = 195a
MD = 0a1c2d555bbe431ad6288af5a54f93e0449c9232

Len = 24
Msg = df4bd2
MD = bf36ed5d74727dfd5d7854ec6b1d49468d8ee8aa
