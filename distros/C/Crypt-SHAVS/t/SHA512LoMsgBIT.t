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
#  "SHA-512 LongMsg" information 
#  SHA-512 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:32 2011

[L = 64]

Len = 1123
Msg = 1583138aa307401dddc40804ac0f414d338fc3ffb2946f09aaaa7079426fc1eee9a1ef503d7b21be2b4255c8581becdfc01f69099eb176da8b0f289fe92883dc82ae41f96d6bcf3832d899ea2dec87e33832c72b841ecef6c8a199d69efb393029d18eedfc7f537137af5ad1f32b1940e1ef66cb2d837f47a9874d87278fead226326093b25eb45385ee23e560
MD = c3359ce7685bb4a1423d6ca98fefeac705fa8f0270906e284dce6319ae53013f283c54b48289944bce5bcae60a4edf2f05e090d5090923add1b2d9c7ff6cbef8

Len = 1222
Msg = 25e20a28fd1f47daeb87b9c1bcc338e7a24c2ba7da7e4b648befaa7bf2fef375bcaff382b3b658239dd1b926615bd7d76c1f2375536a80e3ba6449a0749f96f9ecf1bb7dc37f12b2ba1bfb06d3d02008b3bafed84b1ba1dcb7acaeb56631a7727c506b0374a3fcf00a0c854b58499ce33fc8c4ba08bc36b94b70e1a310dbaf4835760afb104a9f45544d61db39eed1ced7ef7d02d373c7e13c
MD = 1cd686ecd10ab786682a4dacd49063713cd53aae0a7e048c6ec820a887c18135a957d8c17d21739379116465bba27baaa1d40a81a35310068c63bf2a9d95fcb0

Len = 1321
Msg = 1d259612e6867e7d788c71d03c5136864ad6d84f24eaf913a34e69333116f812395288d4dcee6665e6d7dabd005ffc6327e3ca305cab78569d1107a115e619fc90110436317925066726774d1da3639c31a6daf628f2a2d7207ded7405ce304508aa32c14def6469e4c07007fbe2143852663128ef891f9d12d844376b98e5f68b643bfc9918ca9446eeee7402e7b73f716df64e183698b05d6b336fae0adf150089476f7b80
MD = 47a890a1e0b81d38c1eb520f49657137d23a3e6354dec7cd22054be1a54543b5401d328926bbdb1ac6415a6c0ee861e1a5698d1ec3d1c6e0d37736da4b4374fe

Len = 1420
Msg = 8a169a0c6b1fbe21e8b419f9e089a6773d2fba67277fdc07783cd6c570f40c4bab270db94fac68318a4fc1993cbf239cf0a898f2111cf7e25b37fe058f03a04c6b99a044d9895f99677cf3daf718787bb724ab2054edb5196be844284198e08bb3b27d3670804c616583d742795c4d1c7bed1a7858bbbbb29296d1b8ed7d740f6cbcc9177b57d78f6eab965b2a53498522490e83864db4b8b68bcc3dfd7803e07cfdaf6d64d7a72d693e58ad73c415c09680
MD = d2b21234a48263071284101883182ff92403b8d2f77c29e60762d7de6773172a3da41e4527c19eedbd17741fa73c3bdfd592066d5af6d4d8b5a91fee381890d8
