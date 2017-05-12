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
#  CAVS 11.0
#  "SHA-224 ShortMsg" information 
#  SHA-224 tests are configured for BYTE oriented implementations
#  Generated on Tue Mar 15 08:23:36 2011

[L = 28]

Len = 0
Msg = 00
MD = d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f

Len = 8
Msg = 84
MD = 3cd36921df5d6963e73739cf4d20211e2d8877c19cff087ade9d0e3a

Len = 16
Msg = 5c7b
MD = daff9bce685eb831f97fc1225b03c275a6c112e2d6e76f5faf7a36e6

Len = 24
Msg = 51ca3d
MD = 2c8959023515476e38388abb43599a29876b4b33d56adc06032de3a2
