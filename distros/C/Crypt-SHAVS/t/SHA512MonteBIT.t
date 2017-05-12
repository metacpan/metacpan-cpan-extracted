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
#  CAVS 11.1
#  "SHA-512 Monte" information for "sha_values"
#  SHA-512 tests are configured for BIT oriented implementations
#  Generated on Wed May 11 16:56:23 2011

[L = 64]

Seed = 411563c9975deb4fe80276830e835304828a5cd87c7934a55c45cc2349872cd118d070e76f3d108c2a4c654afdee69bf5bdebf959730f3b44a2d02b5f45e1d9a

COUNT = 0
MD = 36d3ba7dcc55917599fbdd7e09d3fb53d5a85cdc8550a16a1c3503be637302b8f0574a8849bf7895d62240947067baffcfe7138737e704750eb82155f3ec5021

COUNT = 1
MD = 6b236ebe3a009a6c955137de4154f8d9767e171a51ac7d1977cf5c0f25c6abf4c00882207f2787d3ecede4c7c436ae936185da75f4eaaafb783fc5815fd74661

COUNT = 2
MD = 9531df1a76877295ea821173531e86b7b53c9cf4eda3b4c9f0581719a238a7d9bde616c02edd76e93cc61c28bdddd5446441d1d9d65e821f1fddb530ddb949a9

COUNT = 3
MD = 3432f43d7adab053bf252f6dd6fcf3e336cc61de9e8283ff620c3022f4c74be11c79d710d698a742f76a7887f43b6cb9dcf895033a734810d8926a33353e05fd
