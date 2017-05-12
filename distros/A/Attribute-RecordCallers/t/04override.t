#!perl

use strict;
use warnings;
use Test::More tests => 6;
use Attribute::RecordCallers;

sub mylog : RecordCallers { log shift }

BEGIN { *CORE::GLOBAL::log = \&mylog }

#line 100
my $l = log 10;

ok(exists $Attribute::RecordCallers::callers{'main::mylog'}, 'seen a caller');
is(scalar @{$Attribute::RecordCallers::callers{'main::mylog'}}, 1, 'seen exactly 1 call');
for my $c (@{$Attribute::RecordCallers::callers{'main::mylog'}}) {
    is($c->[0], 'main', 'caller package is main');
    like($c->[1], qr/04override\.t$/, 'file name is correct');
    is($c->[2], 100, 'line number is correct');
    ok($c->[3] - time < 10, 'time is correct');
}
