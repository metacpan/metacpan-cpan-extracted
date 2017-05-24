package t::lib::TestApp;
use Dancer2;
use Data::Dumper;
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
			]
    },
	}
}

use Dancer2::Plugin::Cart;

get '/' => sub {
  'Hello World'
};

get '/cart/new/' => sub {
  my $cart = cart;
  $cart->{name};
};

get '/cart/new/:cart_new?' => sub {
  my ($cart_name) = param('cart_new'); 
  my $cart = cart; 
  scalar @{$cart->{items}};
};

post '/cart/add_product' => sub {
  my $product = { ec_sku => param('ec_sku'), ec_quantity => param('ec_quantity') };
  my $res = cart_add_item($product);
  $res->{error} ? $res->{error} : Dumper($res);
};

post '/cart/add_product_bar' => sub {
  my $product = { ec_sku => param('ec_sku'), ec_quantity => param('ec_quantity') };
  my $res = cart_add_item($product, { schema => 'bar' });
  $res->{error} ? $res->{error} : Dumper($res);
};

get '/cart/products' => sub {
  Dumper(cart->{cart}->{items});
};

get '/cart/clear_cart/' => sub {
  clear_cart;
  Dumper(cart->{cart}->{items});
};

get '/cart_' => sub {
  Dumper(cart);
};
get '/cart/clear_cart' => sub {
  clear_cart;
  Dumper(cart->{items});
};

get '/cart/subtotal' => sub {
  subtotal;
};

get '/cart/quantity' => sub {
  quantity;
};
1;
