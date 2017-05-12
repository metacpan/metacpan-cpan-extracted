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
#  "SHA-1 LongMsg" information 
#  SHA tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:06 2011

[L = 20]

Len = 611
Msg = d372b4bf97daa3be77e0d78c123c7bb39dde10c82824c83f2250308320391247da419a167686b7320a5dc49b5cfc686eec76bb7034edaaeb2e029cb91791569e739c1bdb518418ffd07f0001e0
MD = c60a02fffa45deccb075e386be3aa9313c2df4f2

Len = 710
Msg = 9c270d3bc0f24cd817a15e8999a305cf4d2eac420229b28e404806bc7e79f4b3957f3efe75dc6fcf17f56c44b3714cea32e26980e6a7b7fd791155d423c4627620601218626101b78344c75afdeccc989d435e59352400e190
MD = 2674630c2dbc2d6ef7dde647f292f5169501ecff

Len = 809
Msg = 94cc2d9a9417ad399a9b9c4242970913c4748d7418568dc95ef1b98d7c9ed8fb09adc80e6afdc0ac3acbd91ef0c8cdc4bb6efe07b193ba8e293fbdb565bbf73b75ea903a57dc2a5d63a1664de75ba96c0e9720c606de014561861424bcce73a59f2b8e07a580
MD = 0aadec36139d9e80073bd815c4464d6e9375bbf5

Len = 908
Msg = 7ed059eba16ea6d3c3bfd32f49a018e6ce4f8e41c97dee9f69a49c6bc49ae54c3167859bf2546d1a1744c3e39e47299edf6d42f728d87250a415e6b281add50a51f60592b12f908d29cce837540f19fc41d84ee818be975f015ee90e41f36721a628dfb6262a9892c3004b13b21f6f66bb30
MD = 1cfcdee05dc37e298e333666b2e1d0ec5989d094
