use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Base64 ":all";

# TODO: test variants
# TODO: test more input

is(sodium_bin2base64("foobar"), "Zm9vYmFy", "sodium_bin2base64 correct");
is(sodium_base642bin("Zm9vYmFy"), "foobar", "sodium_base642bin correct");
is(sodium_base642bin("Zm9vYmFy:lala"), "foobar", "sodium_base642bin stops parsing at invalid base64");

done_testing();
