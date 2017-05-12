#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use Bit::MorseSignals::Receiver;

my $hlagh;

my $pants = Bit::MorseSignals::Receiver->new(done => sub { $hlagh = $_[1] });

my $msg  = 'x';
my @bits = split //, '111110' . '000' . '00011110' . '011111';

$pants->push($_) for @bits;

is($hlagh,      $msg, 'message properly received');
is($pants->msg, $msg, 'message properly stored');
