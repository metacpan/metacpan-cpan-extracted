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

my $sha512BIT = sub {Digest::SHA->new(512)->add_bits($_[0], $_[1])->digest};

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new($sha512BIT, 1)->check($vectors);
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
#  "SHA-512 ShortMsg" information
#  SHA-512 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:31 2011

[L = 64]

Len = 0
Msg = 00
MD = cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e

Len = 1
Msg = 00
MD = b4594eb12959fc2e6979b6783554299cc0369f44083a8b0955baefd8830cda22894b0b46c0ed49490e391ad99af856cc1bd96f238c7f2a17cf37aeb7e793395a

Len = 2
Msg = 40
MD = a726c0deb12ba0c375cc75ec974f567c08c8d921d78fc8d0a05bfc644d0730ea5716970f2006b4599264d4145dc579b118113ffa1690040e4d98ed2d3450e923

Len = 3
Msg = 80
MD = eab930dc76e5ba2fc5b465cef5d10e8a3440c15298cca4bbf2a9f3d196678ebcd26ae6935260f832ac51e353946f328521c912bc6489c8c6db3a73fa75fb3b96
