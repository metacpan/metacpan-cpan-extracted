use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 14;

use Dancer2;

BEGIN {
    set plugins => {
        EncryptID => {
            secret => 'secret_dance',
            padding_character => '!'
        },
    };
}

use Dancer2::Plugin::EncryptID;

##
## Test encoding of 8 bytes or less
##
is( dancer_encrypt(91134), '8fcc5f91ca601c5e', "Encode-Numeric-ID" );
is( dancer_encrypt("91134"), '8fcc5f91ca601c5e', "Encode-Numeric-String-ID" );
is( dancer_encrypt("Hello"), '30fc4406d04d9737', "Encode-String-ID" );
is( dancer_encrypt(0), 'c98ea08a8e8ad715', "Encode-numeric-zero-ID" );
is( dancer_encrypt("000"), '57c668d9dfb75728', "Encode-string-zero-ID" );
is( dancer_encrypt(9999999), 'b8028cf1fa2c3db6', "Encode-7-digits" );
is( dancer_encrypt(99999999), '025f1dec490ea09f', "Encode-8-digits" );
is( dancer_encrypt('HappyJoy'), 'eb25df0ba087ef84', "Encode-8-letters" );
is( dancer_encrypt('d4nc3r^$'), '7e0c23d38f9ef7cc', "Encode-non-alnum" );
is( dancer_encrypt(''), '9b970c430b777c47', "Encode-Empty-String" );

##
## Test Encoding of 9-to-16 bytes (two 8-bytes blocks)
##
is ( dancer_encrypt("HelloWorld"), '576c89e8619c2445c155755044a2033a', 'Encode-String-9-chars');
is ( dancer_encrypt("OnTheDanceFloor"), '3f0ac3bb98036b9b06f98d41960da14e', 'Encode-String-15-chars');
is ( dancer_encrypt("OnThe%DanceFloor"), '37de7572c25e993570695b2a3ad32e2e', 'Encode-String-16-chars');

#This is why it's inheritely insecure - no chaining, IV or salt used
is ( dancer_encrypt("OnThe%DanceFloor"),
	dancer_encrypt("OnThe%Da") . dancer_encrypt("nceFloor"), 'Encode-No-Chaining');