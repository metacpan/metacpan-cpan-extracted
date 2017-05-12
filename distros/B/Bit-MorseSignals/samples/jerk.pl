#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{blib/lib};
use Bit::MorseSignals::Emitter;
use Bit::MorseSignals::Receiver;

my $deuce = Bit::MorseSignals::Emitter->new;
my $pants = Bit::MorseSignals::Receiver->new(done => sub { print $_[1], "\n" });

$deuce->post('HLAGH') for 1 .. 3;
$pants->push while defined ($_ = $deuce->pop);
