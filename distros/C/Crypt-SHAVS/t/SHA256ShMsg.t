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
#  CAVS 11.0
#  "SHA-256 ShortMsg" information
#  SHA-256 tests are configured for BYTE oriented implementations
#  Generated on Tue Mar 15 08:23:38 2011

[L = 32]

Len = 0
Msg = 00
MD = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

Len = 8
Msg = d3
MD = 28969cdfa74a12c82f3bad960b0b000aca2ac329deea5c2328ebc6f2ba9802c1

Len = 16
Msg = 11af
MD = 5ca7133fa735326081558ac312c620eeca9970d1e70a4b95533d956f072d1f98

Len = 24
Msg = b4190e
MD = dff2e73091f6c05e528896c4c831b9448653dc2ff043528f6769437bc7b975c2
