package Test::Cart;

use Test::More;
use Test::Deep;
use Test::Exception;

use Dancer qw/setting var/;
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Interchange6::Cart;

use Test::Roo::Role;

test 'cart unit tests' => sub {
    #plan tests => 21;

    my $self   = shift;
    my $schema = $self->ic6s_schema;
    $self->trap->read;

    my ( $cart, $log );

    # new cart with no args

    lives_ok { $cart = Dancer::Plugin::Interchange6::Cart->new }
    "new cart with no args lives";

    $log = $self->trap->read->[0];
    cmp_deeply(
        $log,
        { level => "debug", message => re(qr/^New cart \d+ main\.$/) },
        'debug: New cart \d+ main.'
    ) or diag explain $log;

    cmp_ok $schema->resultset('Cart')->count, '==', 1, "1 cart in the database";

    cmp_ok $cart->dbic_cart->id, '==', $cart->id, "Cart->id is set";

    # get same cart

    lives_ok { $cart = Dancer::Plugin::Interchange6::Cart->new }
    "repeat new cart with no args lives";

    $log = $self->trap->read->[0];
    cmp_deeply(
        $log,
        { level => "debug", message => re(qr/^Existing cart: \d+ main\.$/) },
        'debug: Existing cart: \d+ main.'
    ) or diag explain $log;

    cmp_ok $schema->resultset('Cart')->count, '==', 1, "1 cart in the database";

    # new cart with args

    lives_ok {
        $cart = Dancer::Plugin::Interchange6::Cart->new(
            database => 'default',
            name     => 'new',
          )
    }
    "new cart with database and name";

    $log = $self->trap->read->[0];
    cmp_deeply(
        $log,
        { level => "debug", message => re(qr/^New cart \d+ new\.$/) },
        'debug: New cart \d+ main.'
    ) or diag explain $log;

    cmp_ok $schema->resultset('Cart')->count, '==', 2,
      "2 carts in the database";

    # new cart with args as hashref

    lives_ok {
        $cart = Dancer::Plugin::Interchange6::Cart->new(
            database => 'default',
            name     => 'hashref',
        );
    }
    "new cart with database, name and sessions_id (undef) hashref";

    $log = $self->trap->read->[0];
    cmp_deeply(
        $log,
        { level => "debug", message => re(qr/^New cart \d+ hashref\.$/) },
        'debug: New cart \d+ hashref.'
    ) or diag explain $log;

    cmp_ok $schema->resultset('Cart')->count, '==', 3,
      "3 carts in the database";

    # add a product to the cart so we can check that it gets reloaded
    # when cart->new is called next time

    lives_ok { $cart = Dancer::Plugin::Interchange6::Cart->new }
    "get default cart";

    cmp_ok $schema->resultset('CartProduct')->count, '==', 0,
      "0 cart_products in the database";

    lives_ok { $cart->add('os28085-6') } "add variant os28085-6";

    cmp_ok $schema->resultset('CartProduct')->count, '==', 1,
      "1 cart_product in the database";

    cmp_ok $schema->resultset('Cart')->find( $cart->id )->cart_products->count,
      '==', 1,
      "our cart has 1 product in the database";

    cmp_ok $cart->count, '==', 1, "cart count is 1";

    lives_ok { $cart = Dancer::Plugin::Interchange6::Cart->new }
    "refetch the cart";

    cmp_ok $cart->count, '==', 1, "cart count is 1";

    cmp_ok $cart->product_get(0)->sku, 'eq', 'os28085-6',
      "and we have the expected product in the cart";

    # cleanup
    $schema->resultset('Cart')->delete;
};

test 'main cart tests' => sub {
    my $self = shift;

    my ( $cart, $cart_id, $product, $name, $ret, @products, $time, $log );

    my $schema = shop_schema;

    # Get / set cart name
    $cart = cart;

    cmp_ok( $schema->resultset('Cart')->count,
        '==', 1, "1 cart in the database" );

    $log = pop @{$self->trap->read};
    cmp_deeply(
        $log,
        { level => "debug", message => re(qr/^New cart \d+ main\.$/) },
        "Check cart debug message"
    ) or diag explain $log;

    $name = $cart->name;
    ok( $name eq 'main', "Testing default name." );

    $name = $cart->rename('discount');
    ok( $name eq 'discount', "Testing custom name." );

    # Products
    $cart     = cart('new');
    $product = {};

    $name = $cart->name;
    ok( $name eq 'new', "Testing cart name." );

    $log = pop @{$self->trap->read};
    cmp_deeply(
        $log,
        { level => "debug", message => re(qr/^New cart \d+ new\.$/) },
        "Check cart debug message"
    ) or diag explain $log;

    $ret = $schema->resultset('Cart')->search( {}, { order_by => 'carts_id' } );
    cmp_ok( $ret->count, '==', 2, "2 carts in the database" );
    my $cart_main_id = $ret->first->id;

    while ( my $rec = $ret->next ) {
        if ( $rec->carts_id == $cart_main_id ) {
            cmp_ok( $rec->name, 'eq', 'discount', "Cart 1 name is discount" );
        }
        else {
            cmp_ok( $rec->name, 'eq', 'new', "Cart 2 name is new" );
        }
    }

    throws_ok { $cart->add() }
    qr/Attempt to add product to cart without sku failed/,
      "add with no args";

    throws_ok { $cart->add(undef) }
    qr/Attempt to add product to cart without sku failed/,
      "add with undef arg";

    throws_ok { $cart->add('this sku does not exist') }
    qr/Product with sku .+ does not exist/, "add sku that does not exist in db";

    # variant
    lives_ok { $ret = $cart->add('os28085-6') } "add variant os28085-6";
    isa_ok( $ret->[0], 'Interchange6::Cart::Product' );
    cmp_ok( $ret->[0]->sku, 'eq', 'os28085-6', "Check sku" );
    cmp_ok( $ret->[0]->canonical_sku, 'eq', 'os28085', "Check canonical_sku" );
    ok( $ret->[0]->is_variant, "product is a variant" );
    ok( !$ret->[0]->is_canonical, "product is not canonical" );
    lives_ok( sub { $cart->clear }, "clear the cart" );
    cmp_ok( $cart->count, '==', 0,
        "Check number of products in the cart is 0" );

    # add os28005 as scalar
    lives_ok { $ret = $cart->add('os28005') } "add single scalar sku";
    isa_ok( $ret->[0], 'Interchange6::Cart::Product' );
    cmp_ok( $ret->[0]->sku, 'eq', 'os28005', "Check sku of returned product" );
    cmp_ok( $ret->[0]->name, 'eq', 'Trim Brush',
        "Check name of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->price ),
        '==', 8.99, "Check price of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->selling_price ),
        '==', 8.99, "Check price of returned product" );
    cmp_ok( $ret->[0]->quantity, '==', 1,
        "Check quantity of returned product is 1" );
    ok( $ret->[0]->is_canonical, "product is canonical" );
    ok( !$ret->[0]->is_variant, "product is not a variant" );
    cmp_ok( $cart->count, '==', 1,
        "Check number of products in the cart is 1" );
    cmp_ok( sprintf( "%.2f", $cart->subtotal ),
        '==', 8.99, "cart subtotal is 8.99" );
    cmp_ok( sprintf( "%.2f", $cart->total ),
        '==', 8.99, "cart total is 8.99" );

    # add os28005 again as hashref
    lives_ok { $ret = $cart->add({ sku => 'os28005'}) }
    "add single hashref without quantity of same product";
    isa_ok( $ret->[0], 'Interchange6::Cart::Product' );
    cmp_ok( $ret->[0]->sku, 'eq', 'os28005', "Check sku of returned product" );
    cmp_ok( $ret->[0]->name, 'eq', 'Trim Brush',
        "Check name of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->price ),
        '==', 8.99, "Check price of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->selling_price ),
        '==', 8.99, "Check price of returned product" );
    cmp_ok( $ret->[0]->quantity, '==', 2,
        "Check quantity of returned product is 2" );
    cmp_ok( $cart->count, '==', 1,
        "Check number of products in the cart is 1" );
    cmp_ok( sprintf( "%.2f", $cart->subtotal ),
        '==', 17.98, "cart subtotal is 17.98" );
    cmp_ok( sprintf( "%.2f", $cart->total ),
        '==', 17.98, "cart total is 17.98" );

    # add qty 8 of os28005 as hashref so qty 10 PriceModifier for anonymous
    # should now apply
    lives_ok { $ret = $cart->add( { sku => 'os28005', quantity => 8 } ) }
    "add single hashref with quantity 8 of same product";
    isa_ok( $ret->[0], 'Interchange6::Cart::Product' );
    cmp_ok( $ret->[0]->sku, 'eq', 'os28005', "Check sku of returned product" );
    cmp_ok( $ret->[0]->name, 'eq', 'Trim Brush',
        "Check name of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->price ),
        '==', 8.99, "Check price of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->selling_price ),
        '==', 8.49, "Check price of returned product" );
    cmp_ok( $ret->[0]->quantity, '==', 10,
        "Check quantity of returned product is 10" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->total), '==', 84.90,
        "Check total of returned product is 84.90" );
    cmp_ok( $cart->count, '==', 1,
        "Check number of products in the cart is 1" );
    cmp_ok( sprintf( "%.2f", $cart->subtotal ),
        '==', 84.90, "cart subtotal is 84.90" );
    cmp_ok( sprintf( "%.2f", $cart->total ),
        '==', 84.90, "cart total is 84.90" );

    # add qty 2 of os28006
    lives_ok { $ret = $cart->add( { sku => 'os28006', quantity => 2 } ) }
    "add single hashref with quantity 2 of os28006";
    isa_ok( $ret->[0], 'Interchange6::Cart::Product' );
    cmp_ok( $ret->[0]->sku, 'eq', 'os28006', "Check sku of returned product" );
    cmp_ok( $ret->[0]->name, 'eq', 'Painters Brush Set',
        "Check name of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->price ),
        '==', 29.99, "Check price of returned product" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->selling_price ),
        '==', 24.99, "Check selling_price of returned product" );
    cmp_ok( $ret->[0]->quantity, '==', 2,
        "Check quantity of returned product is 2" );
    cmp_ok( sprintf( "%.2f", $ret->[0]->total), '==', 49.98,
        "Check total of returned product is 49.98" );
    cmp_ok( $cart->count, '==', 2,
        "Check number of products in the cart is 2" );
    cmp_ok( sprintf( "%.2f", $cart->subtotal ),
        '==', 134.88, "cart subtotal is 134.88" );
    cmp_ok( sprintf( "%.2f", $cart->total ),
        '==', 134.88, "cart total is 134.88" );

    # add array reference of products

    cmp_ok $cart->quantity, '==', 12, "cart quantity is 12";
    lives_ok {
        @products =
          $cart->add( [ 'os28005', { sku => 'os28006', quantity => 3 } ] )
    }
    "add arrayref of os28005 and qty 3 of os28006";
    cmp_ok( $cart->count, '==', 2,
        "Check number of products in the cart is 2" );
    cmp_ok $cart->quantity, '==', 16, "cart quantity is 16";
    cmp_ok @products, '==', 2, "array of 2 products returned";

    # Update product(s)

    throws_ok { $cart->update( os28005 => "hill of beans" ) }
    qr/Bad quantity argument to update: hill of beans/,
      "Bad quantity argument to update";

    lives_ok { $cart->update( os28005 => 10 ) }
    "Change quantity of os28005 to 10";
    lives_ok { $cart->update( os28006 => 5 ) }
    "Change quantity of os28006 to 5";
    cmp_ok( $cart->count, '==', 2, "cart count after update of os28006." );
    cmp_ok( $cart->quantity, '==', 15,
        "cart quantity after update of os28006." );
    cmp_ok( sprintf( "%.2f", $cart->subtotal ),
        '==', 209.85, "cart subtotal is 209.85" );
    cmp_ok( sprintf( "%.2f", $cart->total ),
        '==', 209.85, "cart total is 209.85" );

    lives_ok { $cart->update( os28005 => 20, os28006 => 4 ) }
    "Update qty of os28005 and os28006";
    cmp_ok( $cart->count, '==', 2,
        "cart count after update of os28005 and os28006." );
    cmp_ok( $cart->quantity, '==', 24,
        "cart quantity after update of os28005 and os28006." );
    cmp_ok( sprintf( "%.2f", $cart->subtotal ),
        '==', 269.76, "cart subtotal is 269.76" );
    cmp_ok( sprintf( "%.2f", $cart->total ),
        '==', 269.76, "cart total is 269.76" );

    # product removal

    lives_ok { $cart->update( os28006 => 0 ) }
    "Update quantity of os28006 to 0.";
    cmp_ok( $cart->count, '==', 1, "cart count after update of os28006 to 0." );
    cmp_ok( $cart->quantity, '==', 20,
        "cart quantity after update of os28006 to 0." );
    cmp_ok( sprintf( "%.2f", $cart->total ),
        '==', 169.80, "cart total is 169.80" );

    throws_ok { $cart->remove("NoSuchSkuInTheCart") }
    qr/Product sku not found in cart: NoSuchSkuInTheCart/,
      "Remove SKU that is not in the cart fails";

    # Seed

    lives_ok( sub { var ic6_carts => undef },
        "undef var ic6_carts so new cart will not come from cache" );

    lives_ok { $cart = cart } "Create a new cart";

    $log = $self->trap->read;
    cmp_deeply(
        $log,
        [
            { level => "debug", message => "carts_var_name: ic6_carts" },
            { level => "debug", message => re(qr/^New cart \d+ main\./) },
        ],
        "Check cart debug message"
    ) or diag explain $log;

    $ret = $schema->resultset('Cart')->search( {}, { order_by => 'carts_id' } );
    cmp_ok( $ret->count, '==', 3, "3 carts in the database" );

    my $i = 0;
    while ( my $rec = $ret->next ) {
        $i++;
        if ( $i == 1 ) {
            cmp_ok( $rec->name, 'eq', 'discount', "Cart 1 name is discount" );
        }
        elsif ( $i == 2 ) {
            cmp_ok( $rec->name, 'eq', 'new', "Cart 2 name is new" );
        }
        else {
            cmp_ok( $rec->name, 'eq', 'main', "Cart 3 name is main" );
        }
    }

    lives_ok( sub { $schema->resultset('Cart')->delete_all },
        "delete all carts" );

    cmp_ok( $schema->resultset('Cart')->count, '==', 0, "0 Cart rows" );

    # plugin setting carts_var_name
    
    setting('plugins')->{Interchange6}->{carts_var_name} = "foobar";

    $self->trap->read;

    lives_ok { $cart = cart } "Create a new cart";

    $log = $self->trap->read;
    cmp_deeply(
        $log,
        [
            { level => "debug", message => "carts_var_name: foobar" },
            { level => "debug", message => re('New cart \d+ main') },
        ],
        "Check cart debug message"
    ) or diag explain $log;

    # subclassed cart

    setting('plugins')->{Interchange6}->{carts_var_name} = "ic6_carts";
    setting('plugins')->{Interchange6}->{cart_class} = "TestCart";

    lives_ok( sub { var ic6_carts => undef },
        "undef var ic6_carts so new cart will not come from cache" );

    lives_ok( sub { $cart = cart("test") }, "get new TestCart with name test" );

    isa_ok( $cart, 'TestCart' );
    isa_ok( $cart, 'Interchange6::Cart' );
    ok( $cart->can('add'), "has add method" );
    ok( $cart->can('test_method'), "has test_method" );
    cmp_ok( $cart->name, 'eq', 'test', "name is test" );
    ok( ! defined $cart->test_attribute, "test_attribute is undef" );
    lives_ok( sub { $cart->test_attribute("foobar") }, "set test_attribute" );
    cmp_ok( $cart->test_attribute, 'eq', 'foobar', "has test_attribute" );

    # calling load_saved_products with no logged in user
    ok ! defined $cart->load_saved_products, "load_saved_products";

    # set_sessions_id

    lives_ok {
        $schema->resultset('Session')
          ->create( { sessions_id => "sessionID", session_data => '' } )
    }
    "create a new session record for playing with cart";

    $self->trap->read;
    lives_ok { $cart->set_sessions_id("sessionID") } "set_sessions_id";

    like $self->trap->read->[0]->{message},
      qr/Change sessions_id of cart.+to: sessionID/,
      "check set_sessions_id debug message";

    cmp_ok $cart->dbic_cart->sessions_id, 'eq', 'sessionID',
      "session ID updated in DB cart";
};

1;
