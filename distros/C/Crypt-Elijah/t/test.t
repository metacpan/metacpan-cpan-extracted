use strict;
use Test;

BEGIN {
	plan tests => 2;
}

use Crypt::Elijah;

print('# Using Crypt::Elijah version ' . $Crypt::Elijah::VERSION . "\n");

sub test_api {
	my $key;
	my $keyref;
	my $text;
	my $code;
	my $tmp;
	my $plaintext;
	my $ciphertext;
	my $newciphertext;

	$code = '$keyref = Crypt::Elijah::init($key); 1;';

	print('# Testing normal key input (max. length)... ');
	undef($keyref);
	$key = '0123456789abcdef';
	if (eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Testing normal key input (min. length)... ');
	undef($keyref);
	$key = '0123456789ab';
	if (eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Testing invalid key input (too short)... ');
	undef($keyref);
	$key = '0123456789a';
	if (!eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Testing invalid key arg (undefined)... ');
	undef($keyref);
	undef($key);
	if (!eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Testing invalid key arg (reference)... ');
	undef($keyref);
	$key = \$text;
	if (!eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Checking whether el_key() returns a reference... ');
	undef($keyref);
	$key = '0123456789abcdef';
	if (eval($code) && ref($keyref)) {
		print("Done\n");
	} else {
		return 0;
	}

	$code = 'Crypt::Elijah::enc($text, $keyref); 1;';

	print('# Testing normal encryption... ');
	undef($text);
	$text = 'Jamie works with two hammers';
	$plaintext = $text;
	if (eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}	
	$ciphertext = $text;

	print('# Testing invalid text arg (undefined)... ');
	undef($text);
	if (!eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Testing invalid text arg (reference)... ');
	undef($text);
	$text = \$tmp;
	if (!eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Testing invalid keyref arg (undefined)... ');
	$tmp = $keyref;
	undef($keyref);
	undef($text);
	$text = 'Jamie works with two hammers';
	if (!eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	print('# Testing invalid keyref arg (not a reference)... ');
	undef($text);
	$text = 'Jamie works with two hammers';
	$keyref = "bla";
	if (!eval($code)) {
		print("Done\n");
	} else {
		return 0;
	}

	$keyref = $tmp;
	$text = $ciphertext;

	$code = 'Crypt::Elijah::dec($text, $keyref); 1;';

	print('# Testing normal decryption... ');
	if (eval($code) && ($text eq $plaintext)) {
		print("Done\n");
	} else {
		return 0;
	}

	$text = $plaintext;

	print('# Checking sample usage... ');
	$code = 'no strict;'
		. '$t = \'secret\';'
		. '$k = \'0123456789abcdef\';'
		. '$K = Crypt::Elijah::init($k);'
		. 'Crypt::Elijah::enc($t, $K);'
		. 'Crypt::Elijah::dec($t, $K);';
	if (eval($code)) {
		print("Done\n");
	} else {
		print "$@\n";
		return 0;
	}

	return 1;
}

sub test_cipher_operation { # no test vectors
	my $key;
	my $plaintext;
	my $keyref;
	my $ciphertext;
	my $data;

	my @keys = (
		'ffffffffffffffffffffffffffffffff',
		'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
		'0123456789abcdef0123456789abcdef',
		'000000000000deadbeef000000000000',
		'f01ff23ff45ff67ff89ffabffcdffeff'
	);
	my @plaintexts = (
		'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
		'ffffffffffffffffffffffffffffffff',
		'aabbccddeeff00112233445566778899',
		'01010101010101010101010101010101',
		'00000000000000000000000000000000'
	);

	print('# Checking cipher operation... ');
	while ($key = shift(@keys)) {
		$key = pack('H32', $key);
		$plaintext = shift(@plaintexts); 
		$data = pack('H32', $plaintext);

		$keyref = Crypt::Elijah::init($key);
		Crypt::Elijah::enc($data, $keyref);
		Crypt::Elijah::dec($data, $keyref);
		
		$data = unpack('H32', $data);
		if ($data ne $plaintext) {
			return 0;
		}
	}

	print("Done\n");
	return 1;
}


ok(test_api());
ok(test_cipher_operation());
