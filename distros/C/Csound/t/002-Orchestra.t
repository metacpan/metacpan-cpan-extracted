use strict;
use warnings;

use Test::More   tests => 2;
use Test::Files;

use Csound::Orchestra;
use Csound::Instrument;
use Csound::Score;

my $orc = Csound::Orchestra->new();
isa_ok($orc, 'Csound::Orchestra');

my $instr_1 = Csound::Instrument->new();
my $instr_2 = Csound::Instrument->new();
my $instr_3 = Csound::Instrument->new();

$orc->use_instrument($instr_1);
$orc->use_instrument($instr_1);
$orc->use_instrument($instr_3);
$orc->use_instrument($instr_1);
$orc->use_instrument($instr_3);

my $score = Csound::Score->new();
$orc->write('t/002-gotten.orc', $score);

compare_ok('t/002-gotten.orc', 't/002-expected.orc', '002.orc should be equal');
