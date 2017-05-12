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

my $sha384BIT = sub {Digest::SHA->new(384)->add_bits($_[0], $_[1])->digest};

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new($sha384BIT, 1)->check($vectors);
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
#  "SHA-384 Monte" information for "sha_values"
#  SHA-384 tests are configured for BIT oriented implementations
#  Generated on Wed May 11 16:56:10 2011

[L = 48]

Seed = ef131d0dcad907dbf8c8136e5a895458ced7adc55ee19f01b8f0603ade492d861f55e02846ffc50f115eaa9fe59435b4

COUNT = 0
MD = cae4f1ea8511d3294dc87af1712a75f00964157fcfdc9816db697c268716cb0f4203478dcfc44b592fbdff5d69fdc18f

COUNT = 1
MD = b3d85a6e83612d1c6bae5be8a4b50ee4d5874cbf8d8efd8a1e29d5951174038e97d663429e99eaf8477b9c263086da4c

COUNT = 2
MD = 8d33ee6629092b79e755b73d4d82850029bba8439e725f187627f4572800456201144e947f684e172962c1435c1ea335

COUNT = 3
MD = 8be36aa1326d0df53be8a5b3e6a6f2bdd786fb21f7d8aa4a890dfca640268b93e0cdadafa5b415d13485a6e62a82a11c
