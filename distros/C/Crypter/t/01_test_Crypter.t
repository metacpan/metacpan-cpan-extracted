#!/usr/bin/perl

use 5.022;
use warnings;

use Test::More tests => 2;

use_ok ('Crypter');

ok(test() => 'Crypter working!');

sub test {
	my $crypter = new Crypter(password => '123');
	
	my $encrypted = $crypter->crypt('Hello World!');
	
	$crypter->reset();

	my $decrypted = $crypter->uncrypt($encrypted);
	
	return $decrypted eq 'Hello World!';
}




