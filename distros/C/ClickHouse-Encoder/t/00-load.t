use strict;
use warnings;
use Test::More tests => 3;
use lib 'blib/lib', 'blib/arch';

use_ok('ClickHouse::Encoder');
ok(defined $ClickHouse::Encoder::VERSION, 'version is set');
diag("Testing ClickHouse::Encoder $ClickHouse::Encoder::VERSION, Perl $], $^X");

# Smoke test: minimal encoder construct + encode round-trip.
my $enc = ClickHouse::Encoder->new(columns => [['x', 'UInt32']]);
my $bin = $enc->encode([[42]]);
ok(defined $bin && length($bin) > 0, 'minimal encode produces bytes');
