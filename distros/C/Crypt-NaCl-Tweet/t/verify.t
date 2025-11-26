use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':verify';

ok(verify("\x01" x 16, "\x01" x 16), "same 16 byte values verify");
ok(!verify("\x01" x 16, "\x02" . "\x01" x 15), "different 16 byte values do not verify");

ok(verify_32("\x01" x 32, "\x01" x 32), "same 16 byte values verify");
ok(!verify_32("\x01" x 32, "\x02" . "\x01" x 31), "different 16 byte values do not verify");

done_testing();
