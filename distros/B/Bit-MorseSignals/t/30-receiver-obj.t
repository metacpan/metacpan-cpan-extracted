#!perl -T

use strict;
use warnings;

use Test::More tests => 15;

use Bit::MorseSignals::Receiver;

my $pants = Bit::MorseSignals::Receiver->new;
ok(defined $pants, 'BMR object is defined');
is(ref $pants, 'Bit::MorseSignals::Receiver', 'BMR object is valid');

my $pants2 = $pants->new;
ok(defined $pants2, 'BMR::new called as an object method works' );
is(ref $pants2, 'Bit::MorseSignals::Receiver', 'BMR::new called as an object method works is valid');
ok(!defined Bit::MorseSignals::Receiver::new(), 'BMR::new called without a class is invalid');

eval { $pants2 = Bit::MorseSignals::Receiver->new(qw<a b c>) };
like($@, qr/Optional\s+arguments/, 'BME::new gets parameters as key => value pairs');

my $fake = { };
bless $fake, 'Bit::MorseSignal::Hlagh';
for (qw<push reset busy msg>) {
 eval "Bit::MorseSignals::Receiver::$_('Bit::MorseSignals::Receiver')";
 like($@, qr/^First\s+argument/, "BMR::$_ isn't a class method");
 eval "Bit::MorseSignals::Receiver::$_(\$fake)";
 like($@, qr/^First\s+argument/, "BMR::$_ only applies to BMR objects");
}

{
 local $_;
 ok(!defined($pants->push), 'BMR::push returns undef when \$_ isn\'t defined');
}
