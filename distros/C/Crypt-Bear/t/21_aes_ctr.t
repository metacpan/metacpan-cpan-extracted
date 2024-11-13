#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::AES_CTR;

sub crypt_decrypt {
	my $counter = shift;

	my $key    = make_string(32);
	my $c      = Crypt::Bear::AES_CTR->new($key);
	my $data   = make_string(32 * int rand(16) + 1);
	my $iv     = make_string(16);
 
	my $cipher = $c->run($iv, $counter, $data);
	my $plain  = $c->run($iv, $counter, $cipher);
 
	return {
		data   => $data,
		cipher => $cipher,
		plain  => $plain,
	};
}

sub make_string {
	my $size = shift;
	return pack 'C*', map { rand 256 } 1 .. $size;
}

isa_ok 'Crypt::Bear::AES_CTR', 'Crypt::Bear::CTR';

foreach my $a ( 0 .. 10 ) {
	my $hash = crypt_decrypt($a);
	is($hash->{plain}, $hash->{data}, "Decrypted text matches plain text for cbc-$a");
}

done_testing;
