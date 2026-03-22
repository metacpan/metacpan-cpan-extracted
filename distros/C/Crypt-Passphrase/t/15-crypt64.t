#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passphrase::Util::Crypt64 qw/encode_crypt64 decode_crypt64 encode_crypt64_number decode_crypt64_number/;

{
	my $encoded = encode_crypt64("\0\0\0");
	is $encoded, '....';
	my $decoded = decode_crypt64($encoded);
	is $decoded, "\0\0\0";
}

for my $text (qw/asdkljhasdlkjh fdpoisadujfpo/) {
	my $encoded = encode_crypt64($text);
	my $decoded = decode_crypt64($encoded);
	is $decoded, $text;
}

for my $number (1, 123, 123123) {
	my $encoded = encode_crypt64_number($number, 5);
	my $decoded = decode_crypt64_number($encoded);
	is $decoded, $number, "$number roundtrips";
}

for my $encoded (qw{D U ..../}) {
	my $decoded = decode_crypt64_number($encoded);
	my $recoded = encode_crypt64_number($decoded, length $encoded);
	is $recoded, $encoded, "'$encoded' roundtrips";
}

is length(encode_crypt64_number(234, 5)), 5;

done_testing;
