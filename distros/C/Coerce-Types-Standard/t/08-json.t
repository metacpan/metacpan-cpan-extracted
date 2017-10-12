use Test::More;
use utf8;

BEGIN {
    eval {
        require JSON;
		require Encode;
        JSON->new();
        1;
    } or do {
        plan skip_all => "JSON is not available";
    };
}

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/JSON/;
	use MooX::LazierAttributes;

	attributes (
		decode => [JSON, { coerce => 1 }],
		valid_decode => [JSON->by(['HashRef', 'decode', ['utf8']]), { coerce => 1 }],
		encode => [JSON->by('encode'), { coerce => 1 }],
		valid_encode => [JSON->by(['encode', ['utf8']]), { coerce => 1 }],
		rep_encode => [JSON->by(['encode', ['utf8']]), { coerce => 1 }],
	);
}

use Have::Fun;
use Encode qw/encode/;
my $dec_string = 'ÎÍÎÏÌÌ'; 
my $string = encode('UTF-8', $dec_string);
my $encoded_json = q|{"one":"red bull"}|; 
my $valid_utf8_json = sprintf( '{"one":"%s"}', $string);
my $decode_hash = { one => 'red bull' };
my $valid_hash = { one => $dec_string };

my $thing = Have::Fun->new( 
	decode => $encoded_json, 
	valid_decode => $valid_utf8_json, 	
	encode => $decode_hash,
	valid_encode => $valid_hash,
	rep_encode => $valid_hash,
);

is_deeply($thing->decode, $decode_hash);
is_deeply($thing->valid_decode, $valid_hash);
is($thing->encode, $encoded_json);
is($thing->valid_encode, $valid_utf8_json);
is($thing->rep_encode, $valid_utf8_json);
done_testing();
