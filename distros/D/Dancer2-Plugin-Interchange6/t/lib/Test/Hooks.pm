package Test::Hooks;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::WWW::Mechanize::PSGI;

use Dancer2 '!pass', appname => 'TestApp';
use Dancer2::Plugin::DBIC;

my $app  = dancer_app;
my $trap = $app->logger_engine->trapper;

my $mech = Test::WWW::Mechanize::PSGI->new( app => TestApp->to_app );

sub run_tests {
    diag "Test::Hooks";

    subtest 'before_cart_display hook' => sub {

        # before_cart_display

        $mech->post_ok(
            '/cart',
            { sku => 'os28112', quantity => 2 },
            "POST /cart add os28112 quantity 2"
        );

        $trap->read;

        $mech->get_ok( '/cart', "GET /cart" );
        $mech->base_is( 'http://localhost/cart',
            "seems we're on the correct page" );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_cart_display 1 27.98 27.98'
                }),
            ),
            "before_cart_display hook fired"
        ) or diag explain $logs;
    };

    subtest 'before_checkout_display hook' => sub {

        # before_checkout_display

        $trap->read;

        $mech->get_ok( '/checkout', "GET /checkout" );
        $mech->base_is( 'http://localhost/checkout',
            "seems we're on the correct page" );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_checkout_display 1 27.98 27.98'
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;
    };

    subtest 'before_login_display hook' => sub {

        # before_login_display

        $mech->get_ok( '/logout', "make sure user is logged out" );

        $trap->read;

        $mech->get_ok( '/login?return_url=/there',
            'GET /login?return_url=/there' );

        $mech->base_is( 'http://localhost/login?return_url=/there',
            "check we're on the /login page" );

        $mech->content_like( qr/^Test Login form/,
            'and we have the correct page content' );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_login_display none /there'
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

        $mech->post_ok(
            '/login',
            { username => "badbad", password => "evenworse" },
            'POST /login with bad user/pass'
        ) or diag explain $trap->read;

        $mech->base_is( 'http://localhost/login',
            "check we're on the /login page" );

        $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_login_display Login failed none'
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

    };

    subtest 'before_navigation hooks' => sub {

        # before_navigation_search
        # before_navigation_display

        $mech->get_ok( '/hand-tools', "GET /hand-tools" )
          or diag explain $trap->read;

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level => 'debug',
                    message =>
                      'hook before_navigation_search Hand Tools 1 category',
                }),
                superhashof({
                    level => 'debug',
                    message => 'hook before_navigation_display Hand Tools 1 2 10 category',
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;
    };

    subtest 'before_product_display hook' => sub {

        $mech->get_ok( '/ergo-roller', "GET /ergo-roller" )
          or diag explain $trap->read;

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => re( qr/hook before_product_display os28004 Ergo Roller 21.99/)
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;
    };

    subtest 'cart_add hooks' => sub {

        # before_cart_add_validate
        # before_cart_add
        # after_cart_add

        my $cart;

        lives_ok { schema->resultset('Cart')->delete }
        "clear out any carts in the database";

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005"
        );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_cart_add_validate main 0.00 os28005'
                }),
                superhashof({
                    level => 'debug',
                    message =>
                      'hook before_cart_add main 0.00 os28005 Trim Brush'
                }),
                superhashof({
                    level => 'debug',
                    message => 'hook after_cart_add main 8.99 Dancer2::Plugin::Interchange6::Cart::Product os28005 Trim Brush'
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;
    };

    subtest 'cart_update hooks' => sub {

        # before_cart_update
        # after_cart_update

        $mech->post_ok(
            '/cart',
            { update => 'os28005', quantity => 3 },
            "POST /cart update os28005 quantity 3"
        );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_cart_update main 8.99 os28005 3'
                }),
                superhashof({
                    level   => 'debug',
                    message => 'hook after_cart_update os28005 3 os28005 3'
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

        # remove with qty 0 and we end up with different hooks

        $mech->post_ok(
            '/cart',
            { update => 'os28005', quantity => 0 },
            "POST /cart update os28005 quantity 0"
        );

        $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level => 'debug',
                    message =>
                      'hook before_cart_remove_validate main 26.97 os28005'
                }),
                superhashof({
                    level   => 'debug',
                    message => 'hook before_cart_remove main 26.97 os28005'
                }),
                superhashof({
                    level   => 'debug',
                    message => 'hook after_cart_remove main 0.00 os28005'
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

    };

    subtest 'cart_remove hooks' => sub {

        # before_cart_remove_validate
        # before_cart_remove
        # after_cart_remove

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005"
        );

        $trap->read;

        $mech->post_ok(
            '/cart',
            { remove => 'os28005' },
            "POST /cart remove os28005"
        );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level => 'debug',
                    message =>
                      'hook before_cart_remove_validate main 8.99 os28005'
                }),
                superhashof({
                    level   => 'debug',
                    message => 'hook before_cart_remove main 8.99 os28005'
                }),
                superhashof({
                    level   => 'debug',
                    message => 'hook after_cart_remove main 0.00 os28005'
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

    };

    subtest 'cart_rename hooks' => sub {

        # before_cart_rename
        # after_cart_rename

        $mech->post_ok(
            '/rename_cart',
            { name => 'crazy' },
            "POST /rename_cart name => crazy"
        ) or diag explain $trap->read;

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_cart_rename main main crazy',
                }),
                superhashof({
                    level   => 'debug',
                    message => 'hook after_cart_rename crazy main crazy',
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

        $mech->post_ok(
            '/rename_cart',
            { name => 'name' },
            "POST /rename_cart back to 'main'"
        ) or diag explain $trap->read;

    };

    subtest 'cart_clear hooks' => sub {

        # before_cart_clear
        # after_cart_clear

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005"
        );

        $trap->read;

        $mech->get_ok( '/clear_cart', "GET /clear_cart" );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => 'hook before_cart_clear main 8.99',
                }),
                superhashof({
                    level   => 'debug',
                    message => 'hook after_cart_clear main 0.00',
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

    };

    subtest 'cart_set_users_id hooks' => sub {

        # before_cart_set_users_id
        # after_cart_set_users_id

        $mech->get_ok( '/logout', "make sure we're not logged in" );

        $mech->post_ok(
            '/cart',
            { sku => 'os28005' },
            "POST /cart add os28005"
        );

        $trap->read;

        $mech->post_ok(
            '/login',
            {
                username => 'customer1',
                password => 'c1passwd'
            },
            "POST /login with good password"
        );

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level => 'debug',
                    message =>
                      re(qr/hook before_cart_set_users_id main 8.99 undef \d+/),
                }),
                superhashof({
                    level   => 'debug',
                    message => re(qr/hook after_cart_set_users_id \d+ \d+/),
                }),
            ),
            "check debug logs"
        ) or diag explain $logs;

    };

    subtest 'cart_set_sessions_id hooks' => sub {

        # before_cart_set_sessions_id
        # after_cart_set_sessions_id

        my $result;
        lives_ok {
            $result =
              schema->resultset('Session')
              ->create(
                { sessions_id => 'specialsessionid', session_data => '' } )
        }
        "create a new session result row";

        my $id = $result->id;

        $mech->post_ok(
            '/set_cart_sessions_id',
            { id => $id },
            "POST /set_cart_sessions_id"
        ) or diag explain $trap->read;

        my $logs = $trap->read;
        cmp_deeply(
            $logs,
            superbagof(
                superhashof({
                    level   => 'debug',
                    message => re(
                        qr/hook before_cart_set_sessions_id main 8.99 \S+ $id/),
                }),
                superhashof({
                    level   => 'debug',
                    message => "hook after_cart_set_sessions_id $id $id",
                }),
            ),
            "check debug logs"
        ) or diag explain "id: $id, logs: ", $logs;

    };
}

1;
