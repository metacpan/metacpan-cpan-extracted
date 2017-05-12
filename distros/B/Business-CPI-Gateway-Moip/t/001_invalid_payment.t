# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;
use Data::Printer;
use Business::CPI::Buyer::Moip;
use Business::CPI::Cart::Moip;

BEGIN { use_ok( 'Business::CPI::Gateway::Moip' ); }

ok(my $cpi = Business::CPI::Gateway::Moip->new(
    currency        => 'BRL',
    sandbox         => 1,
    token_acesso    => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
    chave_acesso    => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
    receiver_email  => 'teste@oemail.com.br',
    receiver_label  => 'Nome Cliente ou Loja',
    id_proprio      => 'ID_INTERNO_'.int rand(int rand(99999999)),

), 'build $cpi');

isa_ok($cpi, 'Business::CPI::Gateway::Moip');

ok(my $cart = $cpi->new_cart({
    buyer => {
        name               => 'Mr. Buyer',
        email              => 'sender@andrewalker.net',
    }
},
#   {
#       buyer   => Business::CPI::Buyer::Moip->new(),
#       cart    => Business::CPI::Cart::Moip->new(),
#   }
), 'build $cart');

isa_ok($cart, 'Business::CPI::Cart');

$cart->parcelas([
    {
        parcelas_min => 2,
        parcelas_max => 6,
        juros        => 2.99,
    },
    {
        parcelas_min => 7,
        parcelas_max => 12,
        juros        => 10.99,
    },
]);

ok(my $item = $cart->add_item({
    id          => 1,
    quantity    => 2,
    price       => 111,
    description => 'produto1',
}), 'build $item');

my $res = $cpi->make_xml_transaction( $cart );

ok( $res->{code} eq 'ERROR', 'transacao deve resultar em erro');
done_testing();
