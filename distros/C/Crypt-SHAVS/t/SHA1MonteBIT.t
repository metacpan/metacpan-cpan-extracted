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
#  CAVS 11.1
#  "SHA-1 Monte" information for "sha_values"
#  SHA tests are configured for BIT oriented implementations
#  Generated on Wed May 11 16:55:57 2011

[L = 20]

Seed = 73b955a5fe0acd3e713406ac1b9be80841bd0371

COUNT = 0
MD = b8e4fa4ae4bb5eecfbc94799c4ed1cb9f9b5290a

COUNT = 1
MD = 5e3a50961c4609b056d784d3f3c79802e9979f59

COUNT = 2
MD = 18d254b7aaa0b6cdc6cfa9155322a4dbb0ab7b49

COUNT = 3
MD = b72f7a7a2106cd5822abfd6784f08507d449e36c
