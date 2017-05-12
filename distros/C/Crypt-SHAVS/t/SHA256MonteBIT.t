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
#  CAVS 11.1
#  "SHA-256 Monte" information for "sha_values"
#  SHA-256 tests are configured for BIT oriented implementations
#  Generated on Wed May 11 16:56:02 2011

[L = 32]

Seed = 7d9959cf7db4fa58daf18a1696193dbea425b8acfa01c8cce79154baa7f29028

COUNT = 0
MD = d209f941bd2cae959edd33eb83fe81d7bddfbcc687bcb65f3855ce3738b2f45b

COUNT = 1
MD = e0df1036e4fa3663ade323b3c5e77715eae321bbe6c3abc12a46898d972a127b

COUNT = 2
MD = 34a6fc2b0951a2c1e629a0aefe56066991f8876a0b8cd55fb75932e28e827746

COUNT = 3
MD = 7ee648bb66e0eeb42bec0819ae2e09ab2ec1a794a74aa6f9966d0afca74bf769
