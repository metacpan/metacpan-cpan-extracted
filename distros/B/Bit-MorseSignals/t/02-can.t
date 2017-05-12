#!perl -T

use strict;
use warnings;

use Test::More tests => 9 + 5;

require Bit::MorseSignals::Emitter;

for (qw<new post pop len pos reset flush busy queued>) {
 ok(Bit::MorseSignals::Emitter->can($_), 'BME can ' . $_);
}

require Bit::MorseSignals::Receiver;

for (qw<new push reset busy msg>) {
 ok(Bit::MorseSignals::Receiver->can($_), 'BMR can ' . $_);
}

