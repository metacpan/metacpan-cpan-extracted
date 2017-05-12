package t::lib::TestApp2;
use Dancer2;
use Dancer2::Plugin::Cart;

hook 'plugin.cart.products' => sub {
  my $ec_cart = session('ec_cart');
  $ec_cart->{products} = [ { ec_sku => 'SU10', ec_price => 10 } ];
  session ec_cart => $ec_cart;
};

1;
