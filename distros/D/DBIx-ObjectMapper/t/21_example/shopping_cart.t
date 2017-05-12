use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;
use DateTime;
use Test::More;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    on_connect_do => [
        q{CREATE TABLE product ( prodkey VARCHAR(16) PRIMARY KEY, title TEXT NOT NULL, price INTEGER NOT NULL )},
        q{CREATE TABLE shopping_cart ( id INTEGER PRIMARY KEY, created TIMESTAMP)},
        q{CREATE TABLE shopping_cart_item (
    shopping_cart_id INTEGER NOT NULL REFERENCES shopping_cart(id),
    prodkey VARCHAR(16) NOT NULL REFERENCES product(prodkey))},
    ]
});

# mapperを作成
my $mapper = DBIx::ObjectMapper->new( engine => $engine );

# テーブルのメタデータを作成
my $product = $mapper->metadata->table( 'product' => 'autoload' );
my $shopping_cart = $mapper->metadata->table( 'shopping_cart' => 'autoload' );
my $shopping_cart_item = $mapper->metadata->table( 'shopping_cart_item' => 'autoload' );

# メタデータをクラスにマッピングする
$mapper->maps(
    $product => 'MapperExample::Product',
);

$mapper->maps(
    $shopping_cart => 'MapperExample::ShoppingCart',
    attributes => {
        properties => {
            items => {
                isa => $mapper->relation(
                    many_to_many => $shopping_cart_item
                        => 'MapperExample::Product',
                   { cascade => 'save_update,delete' },
                ),
            }
        }
    }
);

# メタデータからproductへインサート
$product->insert( prodkey => 'ABC-1', title => 'title1', price => 100 )->execute;
$product->insert( prodkey => 'ABC-2', title => 'title2', price => 200 )->execute;
$product->insert( prodkey => 'ABC-3', title => 'title3', price => 300 )->execute;
$product->insert( prodkey => 'ABC-4', title => 'title4', price => 400 )->execute;

{
    my $session = $mapper->begin_session;
    ok my $prod = $session->get( 'MapperExample::Product' => 'ABC-1' );
    is $prod->title, 'title1';
    is $prod->prodkey, 'ABC-1';
};

{
    my $session = $mapper->begin_session();
    my $prod = $session->search('MapperExample::Product')->execute;

    my $cart = MapperExample::ShoppingCart->new({ created => DateTime->now() });

    # sessionにオブジェクトを登録
    $session->add($cart);

    # カートに商品を追加
    $cart->add_item(@$prod);

    # SQLを明示的に実行
    $session->flush;

    # id を取得
    is my $shopping_cart_id = $cart->id, 1;
    ok $cart->items;
    is $cart->item_num, 4;
};

{
    my $session = $mapper->begin_session;
    ok my $cart = $session->get( 'MapperExample::ShoppingCart' => 1 );

    my $loop_cnt = 0;
    for my $item ( @{$cart->items} ) {
        is $item->title, 'title' . ++$loop_cnt;
    }
    is $loop_cnt, 4;

    $cart->remove_item('ABC-1');
    $session->flush;

    is $cart->item_num, 3;
    is $cart->total_price, 1000;
    is $cart->shipping_charge, 100;
};

is $product->count->execute, 4;

done_testing;
