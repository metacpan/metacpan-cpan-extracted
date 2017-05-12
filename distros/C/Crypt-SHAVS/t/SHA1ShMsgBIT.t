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

my $sha1BIT = sub {Digest::SHA->new(1)->add_bits($_[0], $_[1])->digest};

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new($sha1BIT, 1)->check($vectors);
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
#  SHA-1 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:06 2011

[L = 20]

Len = 0
Msg = 00
MD = da39a3ee5e6b4b0d3255bfef95601890afd80709

Len = 1
Msg = 00
MD = bb6b3e18f0115b57925241676f5b1ae88747b08a

Len = 2
Msg = 40
MD = ec6b39952e1a3ec3ab3507185cf756181c84bbe2

Len = 3
Msg = 80
MD = a37596ec13a0d2f9e6c0b8b96f9112823aa6d961
