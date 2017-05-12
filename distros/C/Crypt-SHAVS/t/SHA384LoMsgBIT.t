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
#  CAVS 11.0
#  "SHA-384 LongMsg" information
#  SHA-384 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:15 2011

[L = 48]

Len = 1123
Msg = fbfe7e910f242a78dd6e69a2ecdd8c2db0a24cfc50d6b10bad6b33ff9f632002813f3dcdf1bbb006d1b81dcd917a1092b1139b29811f40202cb21050f48f15b2bf9bee74d391b94cdef6360d395028786d93ff54f7dcb5c14861f6c910a88338bcf8d8ad3d0e0df20c10fa896bc79e87ed08c2a63873d9950a612b927a17323b814044a1b89a739f63efb26aa0
MD = c8bfddba311b6ba286f0ea1c12dd1d0824eff9d9cdbc8249628500d86c0fb93d49a857ec12c17914a921fbc82d02875a

Len = 1222
Msg = 3709d22cb34d212a30acbe6b6a4654b896cfddf594ed72a76ce161b3f86a8168dee6c2c0c2bb08e3b9f53aed003195f1eeb9473e27f039e113f12c6b8e7307f4e1f06f5ff10699e0b71d5cbcf04a8b50167381558eb4fd62230231b2b30e1528286c0190aaf57b28146a4e5fa45adcdcf645b4c233016733865d9813cf05530e9ca5a0dc555157c3b625355e8228309e7676080e7c9f1f5b20
MD = 1b49f1e51055df9427271eeb96370ee961945a6e9622bd2237d4cc7a561c1c7640269a9591d23cb2cf0b48ac76a060ef

Len = 1321
Msg = 5b80d1cf745b14cb71cbc8dfe0bc7c7358f721c00099b3e250c41c2e1c9455c5ce55ce69f3f31090f9b1a1b7361e27f92d46d1e00d25f37b7b61f0b191385dd427b6637a512c658828dfe38fcefd9f5cacd5fecafe46b0db92789307cccbd5d4ee0d5aa796f05dda89bb590eae3f2ac35e0d6f26dbe634291d73ced9d53605edacc1799acb263eafa1aecadde0ce1156c956ee9baaecc58ea5b967cfb2623545e73a89fbf880
MD = e206d2008ff73389659722a8d7e9f7c6ab96d17fcff0e7693895c00a84300d0c43c4aa931a312005e3284734cf42456f

Len = 1420
Msg = 7d49422e13d9dbc9542023d4c16dbeba2a201f6fc46941547b52975b8900456b48359006441a9329953c34736cd4578aeb4b52bb3afda0e0d73ed9872d9ae1506961609789647353b5f9a23ed345113756bafae456de5a9be64eeb83a20353f687d59b2a083de2115d5f537d1f485488127400334293d84d518cb5970fc302254b982707e93048293577307877658846c8814df023a481bebf00200a9c6055a55cb1ee7655c20e64e4482177042515391fe0
MD = 8354f6c5c8a51ec4ddb5b201a58de23acc680deaf4db23ad6291e9992b56f27b068c901c9fd85b589424a3c5037c4539
