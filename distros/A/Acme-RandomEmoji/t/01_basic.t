use strict;
use warnings;
use Test::More;
use Acme::RandomEmoji 'random_emoji';
use Encode ();

diag Encode::encode_utf8( random_emoji ) for 1..10;
pass "ok";

done_testing;
