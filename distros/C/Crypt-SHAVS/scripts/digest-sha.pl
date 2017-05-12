# digest-sha.pl: check Digest::SHA using NIST SHAVS vectors
#
#	Usage: digest-sha.pl [ BYTE-directory [ BIT-directory ] ]

use strict;
use Crypt::SHAVS;
use Digest::SHA qw(sha1 sha224 sha256 sha384 sha512);

my $module = 'Digest::SHA';

my $ORIGDIR = $ENV{PWD};
my $BYTEDIR = $ARGV[0] || 'BYTE';
my $BITDIR  = $ARGV[1] || 'BIT';
die "Unable to locate BYTE vector directory\n" unless -d $BYTEDIR;
die "Unable to locate BIT vector directory\n" unless -d $BITDIR;

my ($alg, $file);
chdir($BYTEDIR);
for $alg (1, 224, 256, 384, 512) {
	next unless $module->new($alg);
	my $shavs = Crypt::SHAVS->new(\&{"sha" . $alg});
	for $file ("SHA${alg}ShortMsg", "SHA${alg}LongMsg", "SHA${alg}Monte") {
		print "$file-BYTE:\n";
		$shavs->check("$file.rsp");
	}
}

chdir($ORIGDIR); chdir($BITDIR);
for $alg (1, 224, 256, 384, 512) {
	next unless $module->new($alg);
        my $sha = sub {$module->new($alg)->add_bits($_[0], $_[1])->digest};
	my $shavs = Crypt::SHAVS->new($sha, 1);
	for $file ("SHA${alg}ShortMsg", "SHA${alg}LongMsg", "SHA${alg}Monte") {
		print "$file-BIT:\n";
		$shavs->check("$file.rsp");
	}
}
