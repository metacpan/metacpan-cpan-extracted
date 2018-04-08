use strict;
use warnings;

use Test::More;

use Acme::ZeroWidth qw(to_zero_width from_zero_width);

subtest 'to_zero_width' => sub {
    is to_zero_width('v'), "\x{200c}\x{200b}\x{200b}\x{200b}\x{200c}\x{200b}\x{200b}\x{200c}";
};

subtest 'from_zero_width' => sub {
    is from_zero_width("\x{200c}\x{200b}\x{200b}\x{200b}\x{200c}\x{200b}\x{200b}\x{200c}"), 'v';
};

done_testing;
