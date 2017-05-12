use strict;
BEGIN { $^W = 1 }

use Test::More tests => 2;
use DateTime;
use DateTime::Format::Epoch::TAI64;

my $f = DateTime::Format::Epoch::TAI64->new( format => 'string' );

isa_ok($f, 'DateTime::Format::Epoch::TAI64' );

# example from http://cr.yp.to/proto/tai64.txt
my $dt = DateTime->new( year => 1997, month => 10, day => 3,
                        hour => 18, minute => 14, second => 48,
                        time_zone => 'UTC' );
is(unpack("H*", $f->format_datetime($dt)), "4000000034353637",
        '1997-10-3 as string');
