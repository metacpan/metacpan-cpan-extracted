use strict;
BEGIN { $^W = 1 }

use Test::More tests => 2;
use DateTime;
use DateTime::Format::Epoch::TAI64;

my $f = DateTime::Format::Epoch::TAI64->new( format => 'string' );

isa_ok($f, 'DateTime::Format::Epoch::TAI64' );

# example from http://cr.yp.to/proto/tai64.txt
is($f->parse_datetime("\x40\0\0\0\x34\x35\x36\x37")->datetime,
   '1997-10-03T18:14:48', '1997-10-3 as string');
