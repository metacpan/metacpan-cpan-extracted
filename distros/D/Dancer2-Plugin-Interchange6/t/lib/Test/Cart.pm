package Test::Cart;

use Test::More;
use Test::Deep;
use Test::Exception;
use Test::WWW::Mechanize::PSGI;

use Dancer2 appname => 'TestApp';
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Cart;

my $app = dancer_app;
my $trap = $app->logger_engine->trapper;
my $plugin = $app->with_plugin('Dancer2::Plugin::Interchange6');

my $mech = Test::WWW::Mechanize::PSGI->new( app => TestApp->to_app );

sub run_tests {
    diag "Test::Cart";

    $trap->read;    # empty it

    subtest 'cart unit tests' => sub {

        #plan tests => 21;

        my $schema = shop_schema;
        $schema->resultset('Cart')->delete_all;

        my ( $cart, $log );

        # new cart with no args

        lives_ok {
            $schema->resultset('Session')
              ->create( { sessions_id => '123456789', session_data => '' } )
        }
        "create empty session";

        throws_ok { Dancer2::Plugin::Interchange6::Cart->new() }
        qr/Missing required arguments: plugin, schema, sessions_id/,
          "new cart with no args dies"
          or diag explain $trap->read;

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                sessions_id => 123456789,
                schema      => $schema,
                plugin      => $plugin,
            );
        }
        "new cart with minimum args lives" or diag explain $trap->read;

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^New cart \d+ main\.$/)
                }
            ),
            'debug: New cart \d+ main.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 1,
          "1 cart in the database";

        cmp_ok $cart->dbic_cart->id, '==', $cart->id, "Cart->id is set";

        # get same cart

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                sessions_id => 123456789,
                schema      => $schema,
                plugin      => $plugin,
            );
        }
        "repeat new cart with minimum args lives" or diag explain $trap->read;

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^Existing cart: \d+ main\.$/)
                }
            ),
            'debug: Existing cart: \d+ main.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 1,
          "1 cart in the database";

        # new cart with args

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                database    => 'default',
                name        => 'new',
                schema      => $schema,
                sessions_id => 123456789,
                plugin      => $plugin,
              )
        }
        "new cart with database and name";

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^New cart \d+ new\.$/)
                }
            ),
            'debug: New cart \d+ main.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 2,
          "2 carts in the database";

        # new cart with args as hashref

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                {
                    database    => 'default',
                    name        => 'hashref',
                    schema      => $schema,
                    sessions_id => 123456789,
                    plugin      => $plugin,
                }
            );
        }
        "new cart with args as hashref";

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^New cart \d+ hashref\.$/)
                }
            ),
            'debug: New cart \d+ hashref.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 3,
          "3 carts in the database";

        # add a product to the cart so we can check that it gets reloaded
        # when cart->new is called next time

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                schema      => $schema,
                sessions_id => 123456789,
                plugin      => $plugin,
              )
        }
        "get default cart";

        cmp_ok $schema->resultset('CartProduct')->count, '==', 0,
          "0 cart_products in the database";

        lives_ok { $cart->add('os28085-6') } "add variant os28085-6";

        cmp_ok $schema->resultset('CartProduct')->count, '==', 1,
          "1 cart_product in the database";

        cmp_ok $schema->resultset('Cart')->find( $cart->id )
          ->cart_products->count,
          '==', 1,
          "our cart has 1 product in the database";

        cmp_ok $cart->count, '==', 1, "cart count is 1";

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                schema      => $schema,
                sessions_id => 123456789,
                plugin      => $plugin,
              )
        }
        "refetch the cart";

        cmp_ok $cart->count, '==', 1, "cart count is 1";

        cmp_ok $cart->product_get(0)->sku, 'eq', 'os28085-6',
          "and we have the expected product in the cart";

        # cleanup
        $schema->resultset('Cart')->delete;
    };

    subtest 'cart combine' => sub {
        my ( $cart, $db_cart );
        my $schema = shop_schema;

        # clean slate
        $mech->get_ok('/clear_cart', "GET /clear_cart is OK");
        $trap->read;

        # start testing

        $mech->get_ok( '/cart', "GET /cart OK" ) or diag explain $trap->read;

        $mech->content_like( qr/cart=""/, "No products in the cart" );

        lives_ok {
            $schema->resultset('Product')->find('os28005')
              ->update( { combine => 0 } )
        }
        "set combine => 0 for product os28005";

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005 OK"
        );

        $mech->content_like( qr/cart=".+Brush:1:/, "Cart contents look good" );

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005 OK (2nd time)"
        );

        $mech->content_like(
            qr/cart=".+Brush:1:.+Brush:1:/,
            "We see os28005 twice in the cart"
        );

        lives_ok {
            $schema->resultset('Product')->find('os28005')
              ->update( { combine => 1 } )
        }
        "set combine => 1 for product os28005";

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005 OK (3rd time)"
        );

        $mech->content_like(
            qr/cart=".+Brush:1:.+Brush:1:.+Brush:1:/,
            "We see os28005 three times in the cart"
        );

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005 OK (4th time)"
        );

        $mech->content_like(
            qr/cart=".+Brush:1:.+Brush:1:.+Brush:2:/,
            "We see os28005 three times in the cart with qty 2 of last one"
        );

        cmp_ok $schema->resultset('CartProduct')->count, '==', 3,
          '3 rows in CartProduct';

        # load_saved_products

        my $user =
          $schema->resultset('User')->find( { username => 'customer1' } )
          or fail("No user found in db");

        lives_ok {
            $schema->resultset('Cart')->update(
                { users_id => $user->id, sessions_id => undef } )
        }
        "set db cart to look like it is from a previous login";

        cmp_ok $schema->resultset('Cart')->count, '==', 1, "1 cart in the db";

        $mech->get_ok( '/cart', "GET /cart OK" );

        cmp_ok $schema->resultset('Cart')->count, '==', 2, "2 carts in the db";

        $mech->content_like( qr/cart=""/, "No products in the cart" );

        lives_ok {
            $schema->resultset('Product')->find('os28005')
              ->update( { combine => 0 } )
        }
        "set combine => 0 for product os28005";

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005 OK"
        );

        $mech->content_like( qr/cart=".+Brush:1:/, "Cart contents look good" );

        lives_ok {
            $schema->resultset('Product')->find('os28005')
              ->update( { combine => 1 } )
        }
        "set combine => 1 for product os28005";

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005 OK (2nd time)"
        );

        $mech->content_like(
            qr/cart=".+Brush:1:.+Brush:1:/,
            "We see os28005 twice in the cart"
        );

        $mech->get_ok( '/current_user', 'GET /current_user OK' );

        $mech->content_is( 'undef', "content is 'undef' (user not logged in)" );

        $trap->read;
        $mech->post_ok(
            '/login',
            {
                username => 'customer1',
                password => 'c1passwd'
            },
            "POST /login with good password"
        );
        $mech->base_is( 'http://localhost/', "Redirected to /" )
          or diag explain $trap->read;

        $mech->get_ok( '/current_user', 'GET /current_user OK' );

        $mech->content_like( qr/Customer One/,
            "content is good (Customer One is logged in)" );

        $mech->get_ok( '/cart', "GET /cart OK" );

        $mech->content_like(
            qr/cart=".+Brush:.+Brush:.+Brush:.+Brush:/,
            "We see os28005 four times in the cart"
        );

        $mech->content_like(
            qr/total="53.94".+cart=".+Brush:3:/s,
            "One trim brush has quantity 3 (combinable ones) and total is good"
        );

        # cleanup

        lives_ok { $schema->resultset('Cart')->delete_all }
        "delete all carts from database";
    };
}

1;
