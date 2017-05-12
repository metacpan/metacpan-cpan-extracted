
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use English qw(-no_match_vars);

use Class::Business::DK::CPR;

my $cpr = Class::Business::DK::CPR->new(1501729996);

ok($cpr->set_number(1501729988));

dies_ok { $cpr->set_number(); } 'no argument to mutator';

like($EVAL_ERROR, qr/You must provide a CPR number/, 'asserting error message');

dies_ok { $cpr->set_number(1234567890); } 'invalid argument to mutator';

like($EVAL_ERROR, qr/Invalid CPR number parameter/, 'asserting error message');
