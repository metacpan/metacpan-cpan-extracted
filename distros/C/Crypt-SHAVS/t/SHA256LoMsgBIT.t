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
#  "SHA-256 LongMsg" information
#  SHA-256 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:11 2011

[L = 32]

Len = 611
Msg = 58af737f436c07a56f4f5fd18a6822a30174e4eeb1f6ec69bf893ba8c474ca4b2e7f1276e305d181274b0cf0bf1050a556653e5421bf4738bf4bb3046381e81d34fce906f4891d1be07e5283c0
MD = 0c71d6b38aab0a3db8b65a3317fa50190cad982c4e0cd8cf6694579c9cd821b3

Len = 710
Msg = 90d15fb5e724a3705c14263179d5d972e73bd342857dfd2fb73a0f6801b9bb23d475273da7d9a1204a488fea7760a4ccab805aaf33879c1e8adfc260e2bbc3e4019ca6e34e1a3a402ce107b386fa8426ab4c8b5f5d6209e024
MD = 8ac449d4191b083926110a486d2ad2112f6416627c1ae1a636d26181e92939ad

Len = 809
Msg = 8219618b7728ac89237705ecf84012cc7c80293c4cf171d86139449d9361d8fe5b881f33ddd9ebd526ba56a8b24661b831fedba78abb854521e8736156edb5df4eee370bf5b6e62d43ee145ebf931e9942a74c15fe26f8d2be3bf3726fb4244be0b472bac680
MD = b857f827ec3a28a9997600f545cd8e189eb75185c9c8c8e0d046c9247e3c109e

Len = 908
Msg = a5d40c0665d1a2e23579ab094210ea7d9352be729db554b312ef1b42fbb8783e06d1bc0a214553ac47ef3d739a3cc3ddb33262b736b10c86a9f99026866d56b18e974fa3616b2c3b4cd0ce24625cfe54ce5f5f356724a0028573f674135aca9fe62eaf164dcc9656ea244562c0f905aa8ce0
MD = 76bff72fbb110770490ab3ac4a57288a66f281082d4a1b9e5d5b803a4c4c52ff
