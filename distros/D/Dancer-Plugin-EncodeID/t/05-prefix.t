use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 2 ;

# Load the Dancer EncodeID Plugin, with our secret code
use Dancer ':syntax';
use Dancer::Plugin::EncodeID;
my $secret = "Just4nother8#@--";
setting plugins => { EncodeID => { secret => $secret } };

my $word = 12556 ;

is ( decode_id(encode_id($word, "L", ), "L"), $word, "Testing-Prefix-1" ) ;

## Different prefixes shouldn't decode correctly
eval {
	my $cipher = encode_id($word, "L", );
	my $clear = decode_id($cipher, "l" ) ;
};
if ($@) {
	Test::More::pass("Testing-Prefix-bad-1");
} else {
	## failed - because decoding a wrong prefix SHOULD die
	Test::More::fail("Testing-Prefix-Bad-1");
}
