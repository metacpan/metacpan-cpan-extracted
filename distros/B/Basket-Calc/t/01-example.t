#!perl

use Test::More tests => 14;

BEGIN { use_ok('Basket::Calc'); }

use Basket::Calc;
use Scalar::Util qw(looks_like_number);

my $result;

# new instance tests
my $basket = Basket::Calc->new(currency => 'NZD', tax => .15);
isa_ok($basket, 'Basket::Calc');
ok($basket->tax == .15, 'tax rate set');
ok($basket->currency eq 'NZD', 'base currency set');

# add items in base currency
$result = $basket->add_item({ price => 14.90 });
is_deeply(
    $result, {
        price    => 14.90,
        amount   => 14.90,
        quantity => 1,
        currency => 'NZD',
    },
    'add item',
);
is(scalar @{ $basket->items }, 1, 'items increased');

$result = $basket->add_item({ price => 14.90, quantity => 2 });
is_deeply(
    $result, {
        price    => 14.90,
        amount   => 29.80,
        quantity => 2,
        currency => 'NZD',
    },
    'add item with quantity',
);

# calculate totals
$result = $basket->calculate;
is_deeply(
    $result, {
        currency   => 'NZD',
        value      => 51.41,
        net        => 44.70,
        tax_amount => 6.71,
        discount   => 0,
    },
    'calculate totals',
);

# add 20% discount
$result = $basket->add_discount({ type => 'percent', value => .2 });
is_deeply(
    $result, {
        type  => 'percent',
        value => .2,
    },
    'add percent discount',
);

# calculate totals (percent discount)
$basket->add_item({ price => 14.90 });
$basket->add_item({ price => 14.90, quantity => 2 });
$result = $basket->calculate;
is_deeply(
    $result, {
        currency   => 'NZD',
        value      => 41.12,
        net        => 35.76,
        tax_amount => 5.36,
        discount   => 8.94,
    },
    'calculate totals (percent discount)',
);

# add fixed currency amount discount
$result = $basket->add_discount({ type => 'amount', value => 15 });
is_deeply(
    $result, {
        type     => 'amount',
        value    => 15,
        currency => 'NZD',
    },
    'add fixed amount discount',
);

# calculate totals (fixed amount discount)
$basket->add_item({ price => 14.90 });
$basket->add_item({ price => 14.90, quantity => 2 });
$result = $basket->calculate;
is_deeply(
    $result, {
        currency   => 'NZD',
        value      => 34.16,
        net        => 29.7,
        tax_amount => 4.46,
        discount   => 15,
    },
    'calculate totals (fixed amount discount)',
);

# add foreign currency items
$result = $basket->add_item({ price => 59, currency => 'EUR' });
ok(
    $result->{quantity} == 1
        && $result->{price} == 59
        && looks_like_number($result->{amount})
        && $result->{orig_amount} == 59
        && $result->{currency} eq 'NZD'
        && $result->{orig_currency} eq 'EUR',
    'add non-base currency item',
);
$result =
    $basket->add_item({ price => 14.90, currency => 'USD', quantity => 2 });
ok(
    $result->{quantity} == 2
        && $result->{price} == 14.90
        && looks_like_number($result->{amount})
        && $result->{orig_amount} == 29.80
        && $result->{currency} eq 'NZD'
        && $result->{orig_currency} eq 'USD',
    'add non-base currency item with quantity',
);
