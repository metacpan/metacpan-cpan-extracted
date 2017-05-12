use Test::More;
use strict;

BEGIN {
    use_ok('Business::Payment::ClearingHouse');
    use_ok('Business::Payment::ClearingHouse::Charge');
}

my $house = Business::Payment::ClearingHouse->new;

my $charge = Business::Payment::ClearingHouse::Charge->new(
    currency => 'USD',
    number => '4111111111111111',
    subtotal => 100,
    tax => 10
);

my $uuid = $house->preauth($charge);
ok(defined($uuid), 'got uuid from preauth');

$house->postauth($uuid);

my $total = $house->settle;

cmp_ok($total, '==', 110, 'settled amount');

done_testing;