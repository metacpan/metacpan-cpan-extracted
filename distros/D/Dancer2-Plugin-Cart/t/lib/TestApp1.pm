package t::lib::TestApp1;

use Dancer2;

BEGIN{
  set plugins => {
      'Cart' => {
							'product_list' => [
								{
									'ec_sku' => 'SU01',
									'ec_price' => 10,
								},
								{
									'ec_sku' => 'SU02',
									'ec_price' => 15,
								},
								{
									'ec_sku' => 'SU03',
									'ec_price' => 20,
								},
							],
      },
  };
}

use Dancer2::Plugin::Cart;

hook 'plugin.cart.validate_shipping_params' => sub {
  my $ec_cart = session->read('ec_cart');
  my $params = $ec_cart->{shipping}->{form};

  if( $params->{ship_mode} ){
    my $ec_cart = session->read('ec_cart');
    delete $ec_cart->{shipping}->{error};
    $ec_cart->{shipping} = $params;
    session->write('ec_cart', $ec_cart );
  }
  else{
    my $ec_cart = session->read('ec_cart');
    push @{$ec_cart->{shipping}->{error}}, "shipmode not selected";
    session->write('ec_cart', $ec_cart );
  }
};

hook 'plugin.cart.before_cart_add' => sub {
  my $ec_cart = session->read('ec_cart');
  $ec_cart->{add}->{form}->{ec_sku} = 'SUNN' if $ec_cart->{add}->{form}->{ec_sku} eq 'SU01';
  session->write('ec_cart',$ec_cart);
};

hook 'plugin.cart.after_cart_add' => sub {
  my $ec_cart = cart;
  foreach my $item ( @{$ec_cart->{cart}->{items}} ){
    if ( $item->{ec_sku} eq 'SUNN' ){
      $item->{ec_price} = -1;
    }
  }
	session->write('ec_cart', $ec_cart );
};

1;
