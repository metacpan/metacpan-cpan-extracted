#!perl -T

use strict;
use warnings;

use Test::More tests => 25;

use Bit::MorseSignals::Emitter;

my $deuce = Bit::MorseSignals::Emitter->new;
ok(defined $deuce, 'BME object is defined');
is(ref $deuce, 'Bit::MorseSignals::Emitter', 'BME object is valid');

my $deuce2 = $deuce->new;
ok(defined $deuce2, 'BME::new called as an object method works' );
is(ref $deuce2, 'Bit::MorseSignals::Emitter', 'BME::new called as an object method works is valid');
ok(!defined Bit::MorseSignals::Emitter::new(), 'BME::new called without a class is invalid');

eval { $deuce2 = Bit::MorseSignals::Emitter->new(qw<a b c>) };
like($@, qr/Optional\s+arguments/, 'BME::new gets parameters as key => value pairs');

my $fake = { };
bless $fake, 'Bit::MorseSignal::Hlagh';
for (qw<post pop len pos reset flush busy queued>) {
 eval "Bit::MorseSignals::Emitter::$_('Bit::MorseSignals::Emitter')";
 like($@, qr/^First\s+argument/, "BME::$_ isn't a class method");
 eval "Bit::MorseSignals::Emitter::$_(\$fake)";
 like($@, qr/^First\s+argument/, "BME::$_ only applies to BME objects");
}

eval { $deuce->post('foo', qw<a b c>) };
like($@, qr/Optional\s+arguments/, 'BME::post gets parameters after the first as key => value pairs');
ok(!defined($deuce->post(sub { 1 })), 'BME::post doesn\'t take CODE references');
ok(!defined($deuce->post(\*STDERR)), 'BME::post doesn\'t take GLOB references');
