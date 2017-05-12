use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 14;


# Load the Dancer EncodeID Plugin, with our secret code
use Dancer ':syntax';
use Dancer::Plugin::EncodeID;
my $secret = "secret_dance";
setting plugins => { EncodeID => { secret => $secret } };

##
## Test encoding of 8 bytes or less
##
is( encode_id(91134), '8fcc5f91ca601c5e', "Encode-Numeric-ID" );
is( encode_id("91134"), '8fcc5f91ca601c5e', "Encode-Numeric-String-ID" );
is( encode_id("Hello"), '30fc4406d04d9737', "Encode-String-ID" );
is( encode_id(0), 'c98ea08a8e8ad715', "Encode-numeric-zero-ID" );
is( encode_id("000"), '57c668d9dfb75728', "Encode-string-zero-ID" );
is( encode_id(9999999), 'b8028cf1fa2c3db6', "Encode-7-digits" );
is( encode_id(99999999), '025f1dec490ea09f', "Encode-8-digits" );
is( encode_id('HappyJoy'), 'eb25df0ba087ef84', "Encode-8-letters" );
is( encode_id('d4nc3r^$'), '7e0c23d38f9ef7cc', "Encode-non-alnum" );
is( encode_id(''), '9b970c430b777c47', "Encode-Empty-String" );

##
## Test Encoding of 9-to-16 bytes (two 8-bytes blocks)
##
is ( encode_id("HelloWorld"), '576c89e8619c2445c155755044a2033a', 'Encode-String-9-chars');
is ( encode_id("OnTheDanceFloor"), '3f0ac3bb98036b9b06f98d41960da14e', 'Encode-String-15-chars');
is ( encode_id("OnThe%DanceFloor"), '37de7572c25e993570695b2a3ad32e2e', 'Encode-String-16-chars');

#This is why it's inheritely insecure - no chaining, IV or salt used
is ( encode_id("OnThe%DanceFloor"),
	encode_id("OnThe%Da") . encode_id("nceFloor"), 'Encode-No-Chaining');
