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

my $sha224BIT = sub {Digest::SHA->new(224)->add_bits($_[0], $_[1])->digest};

my ($vectors, $check) = ("vec$$.tmp", "chk$$.tmp");
END { 1 while unlink ($vectors, $check) }

my $numtests = 0;
my $fh = FileHandle->new($vectors, "w");
while (<DATA>) { print $fh $_; $numtests++ if /^MD\s*=/ }  close($fh);

$fh = FileHandle->new($check, "w+");
my $stdout = select($fh);
Crypt::SHAVS->new($sha224BIT, 1)->check($vectors);
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
#  SHA-224 tests are configured for BIT oriented implementations
#  Generated on Tue Mar 15 08:29:08 2011

[L = 28]

Len = 0
Msg = 00
MD = d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f

Len = 1
Msg = 80
MD = 0d05096bca2a4a77a2b47a05a59618d01174b37892376135c1b6e957

Len = 2
Msg = 80
MD = ef9c947a47bb9311a0f2b8939cfc12090554868b3b64d8f71e6442f3

Len = 3
Msg = 80
MD = 4f2ec61c914dce56c3fe5067aa184125ab126c39edb8bf64f58bdccd
