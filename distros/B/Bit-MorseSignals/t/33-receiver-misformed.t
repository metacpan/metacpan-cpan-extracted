#!perl -T

use strict;
use warnings;

use utf8;

use Test::More tests => 5;

use Bit::MorseSignals::Receiver;

my $hlagh;

my $pants = Bit::MorseSignals::Receiver->new(done => sub { $hlagh = $_[1] });

my $wrong = "\x{FF}\x{FF}";

my @bits = split //, '001' . '010' . (unpack 'b*', $wrong) . '100';
eval {
 local $SIG{__WARN__} = sub { die "WARNED @_" };
 $pants->push for @bits;
};
ok($@, 'invalid Storable data warns');

$pants->reset;
@bits = split //, '0001' . '001' . (unpack 'b*', $wrong) . '1000';
eval {
 local $SIG{__WARN__} = sub { die "WARNED @_" };
 $pants->push for @bits;
};
ok(!$@,            "third bit lit doesn't warn ($@)");
is($hlagh, $wrong, 'third bit lit defaults to plain');

@bits = split //, '0001' . '110' . (unpack 'b*', $wrong) . '1000';
eval {
 local $SIG{__WARN__} = sub { die "WARNED @_" };
 $pants->push for @bits;
};
ok(!$@,            "unused type doesn't warn ($@)");
is($hlagh, $wrong, 'unused type returns raw data');
