use strict;
use warnings;

use Test::More tests => 8;

use Data::Binary qw(is_text is_binary);

my $text_test = '12345678' x 100;
my $binary1_test = "\f234\f67\cg" x 100;
my $binary2_test = "\f234\xff67\x80" x 100;
my $binary3_test = "12345678" . "\x00" . $text_test;

ok(is_text($text_test), "Plain text is text");
ok(! is_binary($text_test), "Plain text is not binary");

ok(! is_text($binary1_test), "Data >30% control codes is not text");
ok(is_binary($binary1_test), "Data >30% control codes is binary");

ok(! is_text($binary2_test), "Data with high-order bits is not text");
ok(is_binary($binary2_test), "Data with high-order bits is binary");

ok(! is_text($binary3_test), "Data with a single null is not text");
ok(is_binary($binary3_test), "Data with a single null is binary");

1;
