BEGIN {
	eval "use Digest::SHA qw(sha224)";
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
Crypt::SHAVS->new(\&sha224)->check($vectors);
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
#  SHA-224 tests are configured for BYTE oriented implementations
#  Generated on Wed May 11 17:26:02 2011

[L = 28]

Seed = ed2b70d575d9d0b4196ae84a03eed940057ea89cdd729b95b7d4e6a5

COUNT = 0
MD = cd94d7da13c030208b2d0d78fcfe9ea22fa8906df66aa9a1f42afa70

COUNT = 1
MD = 555846e884633639565d5e0c01dd93ba58edb01ee18e68ccca28f7b8

COUNT = 2
MD = 44d5f4a179b33231f24cc209ed2542ddb931391f2a2d604f80ed460b

COUNT = 3
MD = 18678e3c151f05f92a89fc5b2ec56bfc6fafa66d73ffc1937fcab4d0
