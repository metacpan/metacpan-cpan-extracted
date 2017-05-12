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

my $sha256BIT = sub {Digest::SHA->new(256)->add_bits($_[0], $_[1])->digest};

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new($sha256BIT, 1)->check($vectors);
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
#  SHA-256 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:11 2011

[L = 32]

Len = 0
Msg = 00
MD = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

Len = 1
Msg = 00
MD = bd4f9e98beb68c6ead3243b1b4c7fed75fa4feaab1f84795cbd8a98676a2a375

Len = 2
Msg = 80
MD = 18f331f626210ff9bad6995d8cff6e891adba50eb2fdbddcaa921221cdc333ae

Len = 3
Msg = 60
MD = 1f7794d4b0b67d3a6edcd17aba2144a95828032f7943ed26bf0c7c7628945f48
