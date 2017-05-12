#!perl -T

use strict;
use warnings;

use utf8;

use Test::More tests => 7;

use Bit::MorseSignals::Emitter;
use Bit::MorseSignals::Receiver;

my @msgs = qw<€éèë 月語 x tata たTÂ>;

sub cp { join '.', map ord, split //, $_[0] }

my $deuce = Bit::MorseSignals::Emitter->new;
my $pants = Bit::MorseSignals::Receiver->new(done => sub {
 my $cur = shift @msgs;
 ok($_[1] eq $cur, 'got ' . cp($_[1]) . ', expected ' . cp($cur));
});

$deuce->post($_) for @msgs;
$pants->push while defined ($_ = $deuce->pop); # ))<>((

ok(!$deuce->busy, 'emitter is no longer busy after all the messages have been sent');
ok(!$pants->busy, 'receiver is no longer busy after all the messages have been got');

ok(0, 'didn\'t got ' . cp($_)) for @msgs;
