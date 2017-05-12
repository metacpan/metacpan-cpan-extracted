#!perl -w
# $Id: endianspecifiers.t,v 1.1 2009/03/03 20:18:06 drhyde Exp $

use strict;

use Test::More tests => 4;

use Data::Hexdumper qw(hexdump);

is_deeply(hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'n',
    suppress_warnings => 1,
) , hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'S>',
    suppress_warnings => 1,
), "n == S>");

is_deeply(hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'v',
    suppress_warnings => 1,
) , hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'S<',
    suppress_warnings => 1,
), "v == S<");

is_deeply(hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'N',
    suppress_warnings => 1,
) , hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'L>',
    suppress_warnings => 1,
), "N == L>");

is_deeply(hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'V',
    suppress_warnings => 1,
) , hexdump(
    data => join('', map { pack('C', $_) } (0x20 .. 0x3F)),
    number_format => 'L<',
    suppress_warnings => 1,
), "V == L<");
