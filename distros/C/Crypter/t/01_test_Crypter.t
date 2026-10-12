#!/usr/bin/perl

use 5.022;
use warnings;

use Test::More tests => 2;

use_ok ('Crypter');

ok(test() => 'Crypter working!');

sub test {
	my $crypter = new Crypter(password => '123');
	
	my $encrypted = '';
	
	$crypter->crypt(
		input		=> 'Hello World!', 
		output		=> \$encrypted
	);

	my $decrypted = '';

	$crypter->uncrypt(
		input		=> $encrypted,
		output		=> \$decrypted,
	);
	
	return $decrypted eq 'Hello World!';
}




