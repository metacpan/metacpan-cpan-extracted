# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

$| = 1;
use Test;
BEGIN { plan tests => 14 };
use Crypt::SEED;

my $veriFile = 'SEED_VERIFY.txt';

print "Do we have a verification file ready ?...";
ok( (-f $veriFile ? 1 : 0), 1 ); # Check if the verification file exists

my @veriData = readFile($veriFile);
print "Does the file have verification data ?...";
ok( (scalar(@veriData) ? 1 : 0), 1 ); # Have verification data in the file

#my %ukeys;
print "Testing low level functions..............";
ok( \&testLowLevel, scalar(@veriData)*3 );

#my $keyCount = keys %ukeys;
print "Testing addKey, encrypt and decrypt .....";
ok( \&testEncDec, scalar(@veriData) * 3 );

my $seed = new Crypt::SEED($veriData[0]->[1], $veriData[1]->[1]);
print "Method count.............................";
ok($seed->count(), 2);
print "Method addKeys...........................";
ok($seed->addKeys($veriData[2]->[1], $veriData[3]->[1]), 2);
print "Method keyIndex..........................";
ok($seed->keyIndex($veriData[2]->[1]), 2);
print "Method userKeys..........................";
ok( join('', $seed->userKeys()), join('',
	$veriData[0]->[1],
	$veriData[1]->[1],
	$veriData[2]->[1],
	$veriData[3]->[1]));
print "Method hasAKey...........................";
ok( $seed->hasAKey($veriData[0]->[1]), 1);
print "Method findUserKey.......................";
ok( $seed->findUserKey(1), $veriData[1]->[1]);
print "Method replaceKey........................";
ok( $seed->replaceKey($veriData[1]->[1],$veriData[4]->[1]), 1);
print "Confirm replaceKey succeded..............";
ok( $seed->findUserKey(1), $veriData[4]->[1]);
print "Method removeKey.........................";
ok( $seed->removeKey( $veriData[2]->[1] ), $veriData[2]->[1]);
print "Confirm removeKey succeded...............";
ok( defined($seed->hasAKey($veriData[2]->[1]))?0:1,  1);


sub testEncDec {
	my $cnt = 0;
	my $seed = new Crypt::SEED();
	foreach my $r ( @veriData ) {
		my($num, $ukey, $text, $rkeyHex, $cipHex) = @$r;
		my $idx = $seed->addKey($ukey);
		$cnt += defined $idx;
		#$ukeys{$ukey} = $idx;
		my $cipher = $seed->encrypt($text, $idx);
		my $cipHexThis = hexString($cipher);
		$cnt += ( $cipHexThis eq $cipHex );
		my $textBack = $seed->decrypt($cipher, $idx);
		$cnt += ( $textBack eq $text );
	}
	$cnt;
}

sub testLowLevel {
	my $cnt = 0;
	foreach my $r ( @veriData ) {
		my($num, $ukey, $text, $rkeyHex, $cipHex) = @$r;
		#$ukeys{$ukey} = $num;
		
		my $rkey = Crypt::SEED::_roundKey($ukey);
		my $rkeyHexThis = Crypt::SEED::_rkeyToString($rkey);
		$cnt += ( $rkeyHexThis eq $rkeyHex );
		
		my $cipher = Crypt::SEED::_encrypt($text, $rkey);
		my $cipHexThis = hexString($cipher);
		$cnt += ( $cipHexThis eq $cipHex );
		
		my $textBack = Crypt::SEED::_decrypt($cipher, $rkey);
		$cnt += ( $textBack eq $text );
	}
	$cnt;
}

sub hexString {
	my $txt = shift;
	my $hex;
	for(my $i=0; $i<length($txt); $i++) {
		$hex .= sprintf("%02X", int(unpack('C', substr($txt,$i,1))));
	}
	$hex;
}

sub readFile {
	my $file = shift;
	local @ARGV = ($file);
	my @array;
	while(<>) {
		# print;
		chomp;
		my($num, $ukey, $text, $rkeyHex, $cipHex) =
		( m/^(\d+):UKEY=(.{16})\sTEXT=(.{16})\sRKEY=(\S+)\sCIPH=(\S+)/ );
		push @array, [$num, $ukey, $text, $rkeyHex, $cipHex];
	}
	@array;
}

__END__


