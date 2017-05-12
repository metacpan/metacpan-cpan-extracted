package Test::Hooks;

use Test::Deep;
use Test::Exception;
use Test::More;

use Test::Roo::Role;

test 'before_cart_display hook' => sub {
    my $self = shift;

    diag "Test::Hooks";

    # before_cart_display

    $self->mech->post_ok(
        '/cart',
        { sku => 'os28112', quantity => 2 },
        "POST /cart add os28112 quantity 2"
    );

    $self->trap->read;

    $self->mech->get_ok( '/cart', "GET /cart" );
    $self->mech->base_is( 'http://localhost/cart',
        "seems we're on the correct page" );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_cart_display 1 27.98 27.98'
            }
        ),
        "before_cart_display hook fired"
    ) or diag explain $logs;
};

test 'before_checkout_display hook' => sub {
    my $self = shift;

    # before_checkout_display

    $self->trap->read;

    $self->mech->get_ok( '/checkout', "GET /checkout" );
    $self->mech->base_is( 'http://localhost/checkout',
        "seems we're on the correct page" );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_checkout_display 1 27.98 27.98'
            }
        ),
        "check debug logs"
    ) or diag explain $logs;
};

test 'before_login_display hook' => sub {
    my $self = shift;

    # before_login_display

    $self->mech->get_ok('/logout', "make sure user is logged out");

    $self->trap->read;

    $self->mech->get_ok( '/login?return_url=/there',
        'GET /login?return_url=/there' );

    $self->mech->base_is( 'http://localhost/login?return_url=/there',
        "check we're on the /login page" );

    $self->mech->content_like( qr/^Test Login form/,
        'and we have the correct page content' );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_login_display none /there'
            }
        ),
        "check debug logs"
    ) or diag explain $logs;

    $self->mech->post_ok(
        '/login',
        { username => "badbad", password => "evenworse" },
        'POST /login with bad user/pass'
    ) or diag explain $self->trap->read;

    $self->mech->base_is( 'http://localhost/login',
        "check we're on the /login page" );

    $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_login_display Login failed none'
            }
        ),
        "check debug logs"
    ) or diag explain $logs;

};

test 'before_navigation hooks' => sub {
    my $self = shift;

    # before_navigation_search
    # before_navigation_display

    $self->mech->get_ok( '/hand-tools', "GET /hand-tools" )
      or diag explain $self->trap->read;

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level => 'debug',
                message =>
                  'hook before_navigation_search Hand Tools 1 category',
            },
            {
                level => 'debug',
                message =>
                  'hook before_navigation_display Hand Tools 1 2 10 category',
            }
        ),
        "check debug logs"
   ) or diag explain $logs;
};

test 'before_product_display hook' => sub {
    my $self = shift;

    $self->mech->get_ok( '/ergo-roller', "GET /ergo-roller" )
      or diag explain $self->trap->read;

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level => 'debug',
                message =>
                  re(qr/hook before_product_display os28004 Ergo Roller 21.99/)
            },
        ),
        "check debug logs"
    ) or diag explain $logs;
};

test 'cart_add hooks' => sub {
    my $self = shift;

    # before_cart_add_validate
    # before_cart_add
    # after_cart_add

    my $cart;

    lives_ok { $self->ic6s_schema->resultset('Cart')->delete }
    "clear out any carts in the database";

    $self->mech->post_ok(
        '/cart',
        { sku => 'os28005' },
        "POST /cart add os28005"
    );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_cart_add_validate main 0.00 os28005'
            },
            {
                level   => 'debug',
                message => 'hook before_cart_add main 0.00 os28005 Trim Brush'
            },
            {
                level => 'debug',
                message => 'hook after_cart_add main 8.99 Dancer::Plugin::Interchange6::Cart::Product os28005 Trim Brush'
            },
        ),
        "check debug logs"
    ) or diag explain $logs;
};

test 'cart_update hooks' => sub {
    my $self = shift;

    # before_cart_update
    # after_cart_update

    $self->mech->post_ok(
        '/cart',
        { update => 'os28005', quantity => 3 },
        "POST /cart update os28005 quantity 3"
    );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_cart_update main 8.99 os28005 3'
            },
            {
                level   => 'debug',
                message => 'hook after_cart_update os28005 3 os28005 3'
            },
        ),
        "check debug logs"
    ) or diag explain $logs;

    # remove with qty 0 and we end up with different hooks

    $self->mech->post_ok(
        '/cart',
        { update => 'os28005', quantity => 0 },
        "POST /cart update os28005 quantity 0"
    );

    $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_cart_remove_validate main 26.97 os28005'
            },
            {
                level   => 'debug',
                message => 'hook before_cart_remove main 26.97 os28005'
            },
            {
                level   => 'debug',
                message => 'hook after_cart_remove main 0.00 os28005'
            },
        ),
        "check debug logs"
    ) or diag explain $logs;

};

test 'cart_remove hooks' => sub {
    my $self = shift;

    # before_cart_remove_validate
    # before_cart_remove
    # after_cart_remove

    $self->mech->post_ok(
        '/cart',
        { sku => 'os28005' },
        "POST /cart add os28005"
    );

    $self->trap->read;

    $self->mech->post_ok(
        '/cart',
        { remove => 'os28005' },
        "POST /cart remove os28005"
    );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_cart_remove_validate main 8.99 os28005'
            },
            {
                level   => 'debug',
                message => 'hook before_cart_remove main 8.99 os28005'
            },
            {
                level   => 'debug',
                message => 'hook after_cart_remove main 0.00 os28005'
            },
        ),
        "check debug logs"
    ) or diag explain $logs;

};

test 'cart_rename hooks' => sub {
    my $self = shift;

    # before_cart_rename
    # after_cart_rename

    $self->mech->post_ok(
        '/rename_cart',
        { name => 'crazy' },
        "POST /rename_cart name => crazy"
    ) or diag explain $self->trap->read;

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_cart_rename main main crazy',
            },
            {
                level   => 'debug',
                message => 'hook after_cart_rename crazy main crazy',
            },
        ),
        "check debug logs"
    ) or diag explain $logs;

    $self->mech->post_ok(
        '/rename_cart',
        { name => 'name' },
        "POST /rename_cart back to 'main'"
    ) or diag explain $self->trap->read;

};

test 'cart_clear hooks' => sub {
    my $self = shift;

    # before_cart_clear
    # after_cart_clear

    $self->mech->post_ok(
        '/cart',
        { sku => 'os28005' },
        "POST /cart add os28005"
    );

    $self->trap->read;

    $self->mech->get_ok(
        '/clear_cart',
        "GET /clear_cart"
    );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level   => 'debug',
                message => 'hook before_cart_clear main 8.99',
            },
            {
                level   => 'debug',
                message => 'hook after_cart_clear main 0.00',
            },
        ),
        "check debug logs"
    ) or diag explain $logs;

};

test 'cart_set_users_id hooks' => sub {
    my $self = shift;

    # before_cart_set_users_id
    # after_cart_set_users_id

    $self->mech->get_ok('/logout', "make sure we're not logged in");

    $self->mech->post_ok(
        '/cart',
        { sku => 'os28005' },
        "POST /cart add os28005"
    );

    $self->trap->read;

    $self->mech->post_ok(
        '/login',
        {
            username => 'customer1',
            password => 'c1passwd'
        },
        "POST /login with good password"
    );

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level => 'debug',
                message =>
                  re(qr/hook before_cart_set_users_id main 8.99 undef \d+/),
            },
            {
                level   => 'debug',
                message => re(qr/hook after_cart_set_users_id \d+ \d+/),
            },
        ),
        "check debug logs"
    ) or diag explain $logs;

};

test 'cart_set_sessions_id hooks' => sub {
    my $self = shift;

    # before_cart_set_sessions_id
    # after_cart_set_sessions_id

    my $result;
    lives_ok {
        $result = $self->ic6s_schema->resultset('Session')
          ->create( { sessions_id => 'specialsessionid', session_data => '' } )
    }
    "create a new session result row";

    my $id = $result->id;

    $self->mech->post_ok(
        '/set_cart_sessions_id',
        { id => $id },
        "POST /set_cart_sessions_id"
    ) or diag explain $self->trap->read;

    my $logs = $self->trap->read;
    cmp_deeply(
        $logs,
        superbagof(
            {
                level => 'debug',
                message =>
                  re(qr/hook before_cart_set_sessions_id main 8.99 \w+ $id/),
            },
            {
                level   => 'debug',
                message => "hook after_cart_set_sessions_id $id $id",
            },
        ),
        "check debug logs"
    ) or diag explain $logs;

};

1;
