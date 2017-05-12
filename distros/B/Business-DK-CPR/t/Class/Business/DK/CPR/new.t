
use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use English qw(-no_match_vars);

use Class::Business::DK::CPR;

ok(my $cpr = Class::Business::DK::CPR->new(1501729996));

isa_ok($cpr, 'Class::Business::DK::CPR');

dies_ok { $cpr = Class::Business::DK::CPR->new(); } 'no argument to constructor';

like($EVAL_ERROR, qr/You must provide a CPR number/, 'asserting error message');

dies_ok { $cpr = Class::Business::DK::CPR->new(1501720001); } 'invalid argument to constructor';

like($EVAL_ERROR, qr/Invalid CPR number parameter/, 'asserting error message');
