#! perl

use Test::More tests => 6;
use Dancer::Test;

use Dancer ':tests';
use Dancer::Plugin::Nitesi;

my ($sku, $ret);

set plugins => {Nitesi => {Account => {Provider => 'Test'}}};

$ret = cart->add(sku => 'FOO', name => 'Foo Shoes', price => 5, quantity => 2);

ok ($ret, "Add Foo Shoes to cart.")
    || diag "Failed to add foo shoes.";

$ret = cart->count;

ok($ret == 1, "Checking cart count after adding two FOOs.")
    || diag "Count is $ret instead of 1.";

# add item without name
$sku = 'BAR';

$ret = cart->add(sku => $sku, price => 5, quantity => 2);

ok(! defined($ret), "Add bar without name to cart.")
    || diag "Unexpected return value: $ret.";

# use hook to add name
hook 'before_cart_add_validate' => sub {
    my ($cart, $item) = @_;

    $item->{name} = 'Bar skirt';
};

$ret = cart->add(sku => $sku, price => 5, quantity => 2);

ok(ref($ret) eq 'HASH' && $ret->{name} eq 'Bar skirt',
   "Add bar without name to cart, using hook to provide name.")
    || diag "Unexpected return value: $ret.";

# testing message from remove hook
hook 'after_cart_remove' => sub {
    warning "Removing item."
};

$ret = cart->remove('FOO');
ok ($ret, "Remove Foo Shoes from cart.")
    || diag "Failed to remove foo shoes: " . cart->error;

is_deeply read_logs, [
        { level => "warning", message => "Removing item." },
    ];
