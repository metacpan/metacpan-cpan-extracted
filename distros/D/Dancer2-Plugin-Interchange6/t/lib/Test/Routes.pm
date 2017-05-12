package Test::Routes;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;
use Test::WWW::Mechanize::PSGI;

use Dancer2 '!pass', appname => 'TestApp';
use Dancer2::Plugin::Interchange6;

my $app  = dancer_app;
my $trap = $app->logger_engine->trapper;

my $mech = Test::WWW::Mechanize::PSGI->new( app => TestApp->to_app );

sub run_tests {
    diag "Test::Routes";

    my ( $resp, $sessionid, %form, $log, $user, @carts, $product );

    my $schema = shop_schema;

    # make sure user is logged out and there are no existing carts
    $mech->get_ok( '/logout', "make sure we're logged out" )
      || diag explain $trap->read;
    $schema->resultset('Cart')->delete_all;

    $mech->get_ok( '/ergo-roller', "GET /ergo-roller (product route via uri)" );

    $mech->content_like( qr|name="Ergo Roller"|, 'found Ergo Roller' )
      or diag $mech->content;

    $mech->get_ok( '/os28005', "GET /os28005 (product route via sku)" );

    $log = $trap->read;
    cmp_deeply(
        $log,
        superbagof(
            {
                formatted => ignore(),
                level     => "debug",
                message =>
"Redirecting permanently to product uri trim-brush for os28005."
            }
        ),
        "Check 'Redirecting permanently...' debug message"
    ) or diag explain $log;

    $mech->base_is( 'http://localhost/trim-brush', "Check redirect path" );

    # navigation

    $mech->get_ok( '/hand-tools', "GET /hand-tools (navigation route)" )
      or diag explain $trap->read;

    $mech->content_like( qr|name="Hand Tools"|, 'found Hand Tools' );

    $mech->content_like( qr|products="([^,]+,){9}[^,]+"|, 'found 10 products' );

    $mech->get_ok( '/hand-tools/brushes',
        "GET /hand-tools/brushes (navigation route)" )
      or diag explain $trap->read;

    $mech->content_like( qr|name="Brushes"|, 'found Brushes' );

    $mech->content_like( qr|products="[^,]+,[^,]+"|, 'found 2 products' );

    $mech->content_like( qr|products=".*Brush Set|, 'found Brush Set' );

    # nav including page number

    $mech->get_ok( '/hand-tools/2', "GET /hand-tools/2 (page 2)" );

    $mech->content_like( qr|name="Hand Tools"|, 'found Hand Tools' );

    $mech->content_like( qr|products="([^,]+,){6}[^,]+"|, 'found 7 products' )
      or diag $mech->content;

    # cart

    $trap->read;

    $mech->get_ok( '/cart?cart=foobar', "GET /cart?cart=foobar" )
      or diag explain $trap->read;

    $log = $trap->read;
    cmp_deeply(
        $log,
        superbagof(
            {
                formatted => ignore(),
                level     => "debug",
                message   => "cart_route cart name: foobar",
            }
        ),
        "check debug logs for cart name"
    ) or diag explain $log;

    lives_ok {
        $schema->resultset('Cart')->search( { name => 'foobar' } )->delete_all
    }
    "remove foobar cart from database";

    $mech->get_ok( '/cart', "GET /cart" );

    # try to add canonical product which has variants to cart
    $mech->post_ok(
        '/cart',
        { sku => 'os28004' },
        "POST /cart add Ergo Roller"
    );

    $mech->base_is( 'http://localhost/ergo-roller', "Check redirect path" );

    # non-existant variant
    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'orange' },
        "POST /cart add Ergo Roller camel orange"
    );

    $mech->base_is( 'http://localhost/ergo-roller', "Check redirect path" );

    # now add variant
    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'black' },
        "POST /cart add Ergo Roller camel black"
    );

    $mech->base_is( 'http://localhost/cart', "Check redirect path" );

    $mech->content_like( qr/cart_subtotal="16/, 'cart_subtotal is 16.00' );

    $mech->content_like( qr/cart_total="16/, 'cart_total is 16.00' );

    $mech->content_like(
        qr/cart="os28004-CAM-BLK:Ergo Roller:1:16/,
        'found qty 1 os28004-CAM-BLK in cart'
    );

    # add again
    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'black' },
        "POST /cart add Ergo Roller camel black"
    );

    $mech->content_like( qr/cart_subtotal="32/, 'cart_subtotal is 32.00' );

    $mech->content_like( qr/cart_total="32/, 'cart_total is 32.00' );

    $mech->content_like(
        qr/cart="os28004-CAM-BLK:Ergo Roller:2:16/,
        'found qty 2 os28004-CAM-BLK in cart'
    );

    # now different variant
    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'white' },
        "POST /cart add Ergo Roller camel white"
    );

    $mech->content_like( qr/cart_subtotal="48/, 'cart_subtotal is 48.00' );

    $mech->content_like( qr/cart_total="48/, 'cart_total is 48.00' );

    $mech->content_like(
        qr/cart="os28004-CAM-BLK:.+:2:16.+,os28004-CAM-WHT:.+:1:16/,
        'found qty 1 os28004-CAM-WHT in cart and qty 2 BLK'
    ) or diag $mech->content;

    # add non-existant product
    $mech->post_ok( '/cart', { sku => 'POT002' }, "POST /cart add potatoes" );

    $mech->base_is( 'http://localhost/', "Check redirect path" );

    # add variant using variant sku
    $mech->post_ok(
        '/cart',
        { sku => 'os28004-HUM-BLK' },
        "POST /cart add Ergo Roller human black using variant's sku only"
    );

    $mech->content_like( qr/cart_total="64/, 'cart_total is 64.00' )
      or diag $mech->content;

    # remove the variant
    $mech->post_ok(
        '/cart',
        { remove => 'os28004-HUM-BLK' },
        "POST /cart remove Ergo Roller human black using variant's sku only"
    );

    $mech->content_like( qr/cart_total="48/, 'cart_total is 48.00' );

    # remove product not in the cart
    $trap->read;
    $mech->post_ok(
        '/cart',
        { remove => 'definitelynotinthecart' },
        "POST /cart remove product that is not in the cart"
    );

    $log = $trap->read;
    cmp_deeply(
        $log,
        superbagof(
            {
                formatted => ignore(),
                level     => "warning",
                message   => re(qr/^Cart remove definitelynotinthecart error/),
            }
        ),
        "check debug logs for cart remove"
    ) or diag explain $log;

    # update with no quantity
    $mech->post_ok(
        '/cart',
        { update => 'os28004-HUM-BLK' },
        "POST /cart update os28004-HUM-BLK with no quantity"
    );

    # update product not in the cart
    $trap->read;
    $mech->post_ok(
        '/cart',
        { update => 'definitelynotinthecart', quantity => 1 },
        "POST /cart update product that is not in the cart"
    );

    $log = $trap->read;
    cmp_deeply(
        $log,
        superbagof(
            {
                formatted => ignore(),
                level     => "warning",
                message =>
                  re(qr/^Update cart product definitelynotinthecart error/),
            }
        ),
        "check debug logs for cart remove"
    ) or diag explain $log;

    # add product with non-Int quantity
    $trap->read;
    $mech->post_ok(
        '/cart',
        { sku => 'os28004-HUM-BLK', quantity => 1.1 },
        "POST /cart add with non-integer quantity"
    );

    $log = $trap->read;
    cmp_deeply(
        $log,
        superbagof(
            {
                formatted => ignore(),
                level     => "warning",
                message   => re(qr/^Cart add error/),
            }
        ),
        "check debug logs for cart remove"
    ) or diag explain $log;

    # GET /cart
    $mech->get_ok( '/cart', "GET /cart" );

    $mech->content_like( qr/cart_subtotal="48/, 'cart_subtotal is 48.00' );

    $mech->content_like( qr/cart_total="48/, 'cart_total is 48.00' );

    $mech->content_like(
        qr/cart="os28004-CAM-BLK:.+:2:16.+,os28004-CAM-WHT:.+:1:16/,
        'found qty 1 os28004-CAM-WHT in cart and qty 2 BLK'
    );

    # get product by sku that has no uri

    lives_ok {
        $product =
          $schema->resultset('Product')
          ->create(
            { sku => 'NoUri', name => 'No URI', description => '', price => 1 }
          )
    }
    "create product NoUri with no uri";

    # uri is generated on insert so we have to delete the auto-generated one
    lives_ok { $product->update( { uri => undef } ) } "undef product uri";

    $mech->get_ok( '/NoUri', 'GET /NoUri' );

    $mech->base_is( 'http://localhost/NoUri', "uri is /NoUri" );

    # login

    # grab session id - we want to make sure it does NOT change on login
    # but that it DOES change after logout
    # TODO: the session id does NOT currently change on login but it ought to

    $mech->get_ok( '/sessionid', "GET /sessionid" );
    $sessionid = $mech->content;

    $trap->read;
    $mech->get_ok( '/private', "GET /private (login restricted)" )
      or diag explain $trap->read;

    $mech->base_is( 'http://localhost/login?return_url=%2Fprivate',
        "Redirected to /login" );

    $mech->content_like( qr/Login form/, 'got login page' );

    # bad login

    $trap->read;    # clear logs

    $mech->post_ok(
        '/login',
        {
            username => 'testuser',
            password => 'badpassword'
        },
        "POST /login with bad password"
    );

    $mech->content_like( qr/Login form/, 'got login page' );

    $log = $trap->read;
    cmp_deeply(
        $log,
        superbagof(
            {
                formatted => ignore(),
                level     => "debug",
                message   => "Authentication failed for testuser"
            }
        ),
        "Check auth failed debug message"
    ) or diag explain $log;

    # good login

    $mech->get_ok( '/current_user', 'GET /current_user' );

    $mech->content_is( 'undef', "content is 'undef'" );

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

    $log = $trap->read;
    cmp_deeply(
        $log,
        superbagof(
            {
                formatted => ignore(),
                level     => "debug",
                message   => re('Change users_id')
            },
            {
                formatted => ignore(),
                level     => "debug",
                message   => "users accepted user customer1"
            },
        ),
        "users_id set in debug logs and login successful"
    ) or diag explain $log;

    $mech->get_ok( '/current_user', 'GET /current_user' )
      or diag explain $trap->read;

    $mech->content_is( 'Customer One', "content is 'Customer One'" );

    $mech->get_ok( '/sessionid', "GET /sessionid" );

    cmp_ok( $mech->content, 'eq', $sessionid,
        "Check session id has not changed" );

    # we should now be able to GET /private

    $mech->get_ok( '/private', "GET /private (login restricted)" );

    $mech->content_like( qr/Private page/, 'got private page' );

    # price modifiers

    lives_ok(
        sub {
            $user =
              $schema->resultset('User')->find( { username => 'customer1' } );
        },
        "grab customer1 fom db"
    );

    cmp_ok( $user->roles->count, "==", 1, "user has 1 role" );

    $trap->read;
    $mech->post_ok(
        '/cart',
        { sku => 'os28005', quantity => 5 },
        "POST /cart add 5 Trim Brushes"
    ) or diag explain $trap->read;

    $mech->content_like( qr/cart_subtotal="92.95"/, 'cart_subtotal is 92.95' );

    $mech->content_like(
        qr/cart=.+os28005:Trim Brush:5:8.99:8.99:/,
        'found qty 5 os28005 @ 8.99 in cart'
    );

    # authenticated user should get selling_price of 8.20
    # total is 48 for ergo rollers plus 82 for trim brushes = 130
    $mech->post_ok(
        '/cart',
        { sku => 'os28005', quantity => 5 },
        "POST /cart add 5 Trim Brushes"
    );

    $mech->content_like( qr/cart_subtotal="130.00"/,
        'cart_subtotal is 130.00' );

    $mech->content_like(
        qr/cart=.+os28005:Trim Brush:10:8.99:8.20:/,
        'found qty 10 os28005 @ 8.20 in cart'
    );

    # add trade role to user
    lives_ok( sub { $user->add_to_roles( { name => 'trade' } ) },
        "Add user to role trade" );

    # trade user should get selling_price of 7.80
    # total is 48 for ergo rollers plus 78 for trim brushes = 126
    $mech->get_ok( '/cart', "GET /cart" );

    $mech->content_like( qr/cart_subtotal="126.00"/,
        'cart_subtotal is 126.00' );

    $mech->content_like(
        qr/cart=.+os28005:Trim Brush:10:8.99:7.80:/,
        'found qty 10 os28005 @ 7.80 in cart'
    );

    # checkout

    $mech->get_ok( '/checkout', "GET /checkout" ) or diag $mech->content;

    $mech->content_like( qr/cart_subtotal="126.00"/,
        'cart_subtotal is 126.00' );

    $mech->content_like( qr/cart_total="126.00"/, 'cart_total is 126.00' );

    $mech->content_like(
        qr/cart=".+:Ergo Roller:2:16.+,os28004-CAM-WHT:.+:1:16/,
        'found 2 ergo roller variants at checkout' )
      or diag $mech->content;

    @carts = $schema->resultset('Cart')->hri->all;
    cmp_ok @carts, '==', 1, "1 cart in the database";

    # logout

    $mech->get_ok( '/logout', "GET /logout" );

    $mech->base_is( 'http://localhost/', "Redirected to /" );

    $mech->get_ok( '/sessionid', "GET /sessionid" );

    cmp_ok( $mech->content, 'ne', $sessionid, "Check session id has changed" );

    $mech->get_ok( '/private', "GET /private (login restricted)" );

    $mech->base_is( 'http://localhost/login?return_url=%2Fprivate',
        "Redirected to /login" );

    lives_ok { $mech->get('/cart') } "GET /cart";

    $mech->content_like( qr/cart_total="0/, 'cart_total is 0' );

    $mech->content_like( qr/cart=""/, 'cart is empty' );

    # add items to cart then login again to test cart combining via
    # load_saved_products

    lives_ok { $schema->resultset('Cart')->delete } "delete all carts";

    cmp_ok $schema->resultset('Cart')->count, '==', 0, "no carts in the db";
    cmp_ok $schema->resultset('CartProduct')->count, '==', 0,
      "no cart_productss in the db";

    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'white' },
        "POST /cart add Ergo Roller camel white"
    );

    cmp_ok $schema->resultset('Cart')->count, '==', 1, "1 cart in the db";

    $mech->content_like( qr/cart_subtotal="16/, 'cart_subtotal is 16.00' );

    $mech->content_like( qr/cart_total="16/, 'cart_total is 16.00' );

    $mech->content_like(
        qr/cart="os28004-CAM-WHT:.+:1:16/,
        'found qty 1 os28004-CAM-WHT in cart'
    ) or diag $mech->content;

    $mech->post_ok(
        '/login',
        {
            username => 'customer1',
            password => 'c1passwd'
        },
        "POST /login with good password"
    );

    cmp_ok $schema->resultset('Cart')->count, '==', 1, "1 cart in the db";

    $mech->get_ok( '/cart', "GET /cart" );

    $mech->content_like( qr/cart_subtotal="16/, 'cart_subtotal is 16.00' );

    $mech->content_like( qr/cart_total="16/, 'cart_total is 16.00' );

    $mech->content_like(
        qr/cart="os28004-CAM-WHT:.+:1:16/,
        'found qty 1 os28004-CAM-WHT in cart'
    ) or diag $mech->content;

    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'white' },
        "POST /cart add Ergo Roller camel white (again)"
    );

    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'black' },
        "POST /cart add Ergo Roller camel black"
    );

    $mech->content_like(
        qr/cart="os28004-CAM-BLK:Ergo Roller:1:.+,os28004-CAM-WHT:.+:2:16/,
        'found qty 1 os28004-CAM-BLK and qty 2 os28004-CAM-WHT'
    ) or diag $mech->content;

    $mech->content_like( qr/cart_subtotal="48/, 'cart_subtotal is 48.00' );

    cmp_ok $schema->resultset('Cart')->count, '==', 1, "1 cart in the db";

    $mech->get_ok( '/logout', "GET /logout" );

    $mech->base_is( 'http://localhost/', "Redirected to /" );

    $mech->get_ok( '/cart', "GET /cart" );

    @carts = $schema->resultset('Cart')->search(
        undef,
        {
            prefetch => 'cart_products',
            order_by => 'me.carts_id'
        }
    )->hri->all;

    cmp_deeply \@carts,
      [
        superhashof(
            {
                'cart_products' => bag(
                    superhashof(
                        {
                            'cart_position' => 0,
                            'quantity'      => 2,
                            'sku'           => 'os28004-CAM-WHT'
                        }
                    ),
                    superhashof(
                        {
                            'cart_position' => 0,
                            'quantity'      => 1,
                            'sku'           => 'os28004-CAM-BLK'
                        }
                    ),
                ),
                'name'        => 'main',
                'sessions_id' => undef,
                'users_id'    => re(qr/\d/),
            }
        ),
        superhashof(
            {
                'cart_products' => [],
                'name'          => 'main',
                'sessions_id'   => re(qr/\w/),
                'users_id'      => undef
            }
        ),
      ],
      "carts contents are as we expect"
      or diag explain @carts;

    $mech->content_like( qr/cart_subtotal="0\.00/, 'cart_subtotal is 0.00' );

    $mech->post_ok(
        '/cart',
        { sku => 'os28004', roller => 'camel', color => 'white' },
        "POST /cart add Ergo Roller camel white"
    );

    $trap->read;
    $mech->post_ok(
        '/login',
        {
            username => 'customer1',
            password => 'c1passwd'
        },
        "POST /login with good password"
    ) or diag explain $trap->read;

    cmp_ok $schema->resultset('Cart')->count, '==', 1, "1 cart in the db";

    @carts = $schema->resultset('Cart')->search(
        undef,
        {
            prefetch => 'cart_products',
            order_by => 'me.carts_id'
        }
    )->hri->all;

    cmp_deeply \@carts,
      [
        superhashof(
            {
                'cart_products' => bag(
                    superhashof(
                        {
                            'cart_position'    => 0,
                            'quantity'         => 3,
                            'sku'              => 'os28004-CAM-WHT'
                        }
                    ),
                    superhashof(
                        {
                            'cart_position'    => 0,
                            'quantity'         => 1,
                            'sku'              => 'os28004-CAM-BLK'
                        }
                    ),
                ),
                'name'          => 'main',
                'sessions_id'   => re(qr/\w/),
                'users_id'      => re(qr/\d/),
            }
        ),
      ],
      "carts contents are as we expect" or diag explain @carts;

    $mech->get_ok( '/cart', "GET /cart" );

    $mech->content_like(
        qr/cart="os28004-CAM-BLK:Ergo Roller:1:.+,os28004-CAM-WHT:.+:3:16/,
        'found qty 1 os28004-CAM-BLK and qty 3 os28004-CAM-WHT'
    ) or diag $mech->content;

    $mech->content_like( qr/cart_subtotal="64\.00/, 'cart_subtotal is 64.00' );

    # shop_redirect
    $mech->get( '/old-hand-tools', "GET /old-hand-tools" );

    cmp_ok( $mech->status, 'eq', '404', 'status is not_found' );

    $schema->resultset("UriRedirect")->delete;

    scalar $schema->resultset("UriRedirect")->populate(
        [
            [qw/uri_source      uri_target  status_code/],
            [qw/old-hand-tools  hand-tools  301/],
            [qw/one             two         301/],
            [qw/two             hand-tools  302/],
            [qw/bad1            bad2        301/],
            [qw/bad2            bad3        301/],
            [qw/bad3            bad1        302/],
        ]
    );

    cmp_ok( $schema->resultset('UriRedirect')->count,
        '==', 6, "6 UriRedirect rows" );

    $mech->get_ok( '/old-hand-tools', "GET /old-hand-tools" );

    $mech->base_is( 'http://localhost/hand-tools', 'redirect is ok' );

    $mech->get_ok( '/one', "GET /one" );

    $mech->base_is( 'http://localhost/hand-tools', 'redirect is ok' );

    lives_ok { $mech->get('/bad1') } "circular redirect";

    cmp_ok( $mech->status, 'eq', '404', 'status is not_found' );

    # get product using sku

    $mech->get_ok( '/os28004', 'GET /os28004' );

    $mech->base_is( 'http://localhost/ergo-roller',
        'redirected to /ergo-roller' );

    # inactive product

    lives_ok {
        $schema->resultset('Product')->find('os28004')
          ->update( { active => 0 } )
    }
    "set os28004 to inactive";

    $mech->get('/os28004');

    ok $mech->status eq '404', "os28004 is now 404 not found"
      or diag $mech->status;

    lives_ok {
        $schema->resultset('Product')->find('os28004')
          ->update( { active => 1 } )
    }
    "set os28004 to active again";

    $mech->get_ok( '/os28004', 'GET /os28004' );
}
1;
