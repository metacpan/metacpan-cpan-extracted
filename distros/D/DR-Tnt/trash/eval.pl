#!/usr/bin/perl

use warnings;
use strict;


use DR::Msgpuck;

my $lua = <<eof;
box.session.storage.rettest = function()
    return [ 'test' ]
end
eof

my $pkt = msgpack {
    0x00, 0x08,                         # type - eval
    0x01, 123,                          # sync
};

$pkt .= msgpack {
    0x27, $lua,                         # expression
    0x21, []                            # tuple
};

$pkt = pack('CL>', 0xCE, length $pkt) . $pkt;     # add request length

print $pkt;
