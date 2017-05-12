

use strict;
use ExtUtils::testlib;
use Crypt::SEED;

my $file = "crypt_remote.sed"; # SEED encrypted data
my $userKey = makeUserKey();
print "User Key = ", hexString($userKey), "\n";
my $seed = new Crypt::SEED($userKey);

if($ARGV[0] =~ /^S/i ) { #save
	my $original = makeData();
	my $len = length $original;
	#print "APP Length=$len\n";
	my $cipher = $seed->encrypt($original, 0);
	saveData($cipher);
	print "Original\n", hexString($original), "\n";
	print "Cipher\n", hexString($cipher), "\n";
}
else {
	my $cipher = readData();
	my $original = makeData();
	my $localCipher = $seed->encrypt($original, 0);
	my $recover = $seed->decrypt($cipher,0);
	$recover =~ s/\x00+$//;
	if($cipher eq $localCipher) {
		print "Cipher O.K.\n";
	}
	else {
		print "Cipher not O.K.\n";
		print "Cipher Remote:\n", hexString($cipher), "\n\n";
		print "Cipher Local:\n", hexString($localCipher), "\n";
	}
	
	if($original eq $recover) {
		print "Recovered O.K.\n";
	}
	else {
		print "Recovered BAD.\n";
		print "Recovered:\n", hexString($recover), "\n\n";
		print "Original:\n", hexString($original), "\n";
	}
}	

sub makeData {
	my $data = "Test by exchanging data with other system.\n";
	foreach my $n ( 1..10 ) {
		foreach (0..255) {
			$data .= pack('C', $_);
		}
		$data .= "\t$n\t";
	}

	$data . "END";
}

sub saveData {
	open(F, ">$file") or die "Writing error: $!";
	binmode F;
	print F $_[0];
	close F;
}

sub readData {
	open(F, $file) or die "Reading error: $!";
	binmode F;
	my $dat;
	sysread(F, $dat, -s F);
	close F;
	$dat;
}

sub makeUserKey {
	my $txt  = '0123456789ABCDEF';
	my $ukey = 'QQQQQQQQQQQQQQQQ';
	my $seed = new Crypt::SEED($ukey);
	foreach ( 1..16 ) {
		$txt = $seed->encrypt($txt, 0);
	}
	$txt;
}

sub hexString {
	my $txt = shift;
	my $hex;
	for(my $i=0; $i<length($txt); $i++) {
		$hex .= sprintf("%02X", int(unpack('C', substr($txt,$i,1))));
	}
	$hex;
}
