use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 13;

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
is( dancer_decrypt('8fcc5f91ca601c5e'),91134, "Decode-Numeric-ID" );
is( dancer_decrypt('30fc4406d04d9737'), "Hello",  "Decode-String-ID" );
is( dancer_decrypt('c98ea08a8e8ad715'), 0, "Decode-numeric-zero-ID" );
is( dancer_decrypt('57c668d9dfb75728'), "000", "Decode-string-zero-ID" );
is( dancer_decrypt('b8028cf1fa2c3db6'), 9999999, "Decode-7-digits" );
is( dancer_decrypt('025f1dec490ea09f'), 99999999, "Decode-8-digits" );
is( dancer_decrypt('eb25df0ba087ef84'),"HappyJoy", "Decode-8-letters" );
is( dancer_decrypt('7e0c23d38f9ef7cc'),'d4nc3r^$', "Decode-non-alnum" );
is( dancer_decrypt('9b970c430b777c47'), "", "Decode-Empty-String" );

##
## Test Encoding of 9-to-16 bytes (two 8-bytes blocks)
##
is ( dancer_decrypt('576c89e8619c2445c155755044a2033a'),"HelloWorld", 'Decode-String-9-chars');
is ( dancer_decrypt('3f0ac3bb98036b9b06f98d41960da14e'),"OnTheDanceFloor", 'Decode-String-15-chars');
is ( dancer_decrypt('37de7572c25e993570695b2a3ad32e2e'),"OnThe%DanceFloor",	'Decode-String-16-chars');

#This is why it's inheritely insecure - no chaining, IV or salt used
is ( dancer_decrypt("37de7572c25e993570695b2a3ad32e2e"),
	dancer_decrypt("37de7572c25e9935") . dancer_decrypt("70695b2a3ad32e2e"), 'Decode-No-Chaining');