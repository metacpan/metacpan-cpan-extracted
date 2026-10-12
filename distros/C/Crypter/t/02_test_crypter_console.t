#!/usr/bin/perl

use 5.022;
use warnings;

use File::Temp qw(tempfile);
use FindBin qw($Bin);
use Test::Simple tests => 1;

ok (test_crypted(), 'Test crypter success!');

sub test_crypted {
	my (undef, $filename) = tempfile();

	`cat /dev/random|head -n 10 > $filename`;
	`$Bin/../bin/crypter -i $filename -o $filename.crypted`;
	`$Bin/../bin/crypter -d $filename.crypted -o $filename.uncrypted`;
	my $diff = `diff $filename $filename.uncrypted`;

	unlink $filename;
	unlink $filename.'.crypted';
	unlink $filename.'.crypted.key';
	unlink $filename.'.uncrypted';


	if ($diff) {
		return 0;
	}

	return 1;
}


