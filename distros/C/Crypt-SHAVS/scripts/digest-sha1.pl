# digest-sha1.pl: check Digest::SHA1 using NIST SHAVS vectors
#
#	Usage: digest-sha1.pl [ BYTE-directory ]

use strict;
use Crypt::SHAVS;
use Digest::SHA1 qw(sha1);

my $BYTEDIR = $ARGV[0] || 'BYTE';
die "Unable to locate BYTE vector directory\n" unless -d $BYTEDIR;

my $file;
chdir($BYTEDIR);
my $shavs = Crypt::SHAVS->new(\&sha1);
for $file ("SHA1ShortMsg", "SHA1LongMsg", "SHA1Monte") {
	print "$file-BYTE:\n";
	$shavs->check("$file.rsp");
}
