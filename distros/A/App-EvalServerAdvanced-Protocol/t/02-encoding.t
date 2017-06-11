
use strict;
use warnings;

use utf8;

use App::EvalServerAdvanced::Protocol;
use Test::More;

my $message = encode_message(response => {encoding => "utf8", contents => "\x{2603}", sequence => 42});
my ($res, $decoded) = decode_message($message);

ok($res, "decoding succeeded");

is($decoded->get_contents, "\x{2603}", "utf8 transfers properly");

done_testing;
