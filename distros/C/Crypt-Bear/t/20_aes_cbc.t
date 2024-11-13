#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::AES_CBC::Enc;
use Crypt::Bear::AES_CBC::Dec;


sub crypt_decrypt {
	my $key    = make_string(32);
	my $e      = Crypt::Bear::AES_CBC::Enc->new($key);
	my $d      = Crypt::Bear::AES_CBC::Dec->new($key);
	my $data   = make_string(32 * int rand(16) + 1);
	my $iv     = make_string(16);
 
	my $cipher = $e->run($iv, $data);
	my $plain  = $d->run($iv, $cipher);
 
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

isa_ok 'Crypt::Bear::AES_CBC::Enc', 'Crypt::Bear::CBC::Enc';
isa_ok 'Crypt::Bear::AES_CBC::Dec', 'Crypt::Bear::CBC::Dec';

foreach my $a ( 0 .. 10 ) {
	my $hash = crypt_decrypt();
	is($hash->{plain}, $hash->{data}, "Decrypted text matches plain text for cbc-$a");
}

done_testing;
