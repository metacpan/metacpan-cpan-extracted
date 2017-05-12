package Test::DSL;

use Test::Exception;
use Test::More;
use Test::WWW::Mechanize::PSGI;

use Dancer2 appname => 'TestApp';
use Dancer2::Plugin::Interchange6;

my $app  = dancer_app;
my $trap = $app->logger_engine->trapper;

my $mech = Test::WWW::Mechanize::PSGI->new( app => TestApp->to_app );

sub run_tests {
    subtest 'shop_schema' => sub {

        diag "Test::DSL";

        my $schema;

        lives_ok { $schema = shop_schema } "shop_schema lives";

        isa_ok $schema, "DBIx::Class::Schema";

        lives_ok { $schema = shop_schema('shop2') }
        "shop_schema('shop2') lives";

        isa_ok $schema, "DBIx::Class::Schema";

        throws_ok { $schema = shop_schema('bad') }
        qr/The schema bad is not configured/, "shop_schema('bad') dies";
    };

    subtest 'shop_cart' => sub {

        $mech->post_ok( '/cart_test', 'shop_cart with no args' );
        $mech->content_is( 'Dancer2::Plugin::Interchange6::Cart,main',
            "object type and name are good" );

        $mech->post_ok(
            '/cart_test',
            { name => 'test' },
            'shop_cart with name test'
        );
        $mech->content_is( 'Dancer2::Plugin::Interchange6::Cart,test',
            "object type and name are good" );
    };

    subtest 'shop_charge' => sub {

        my $paymentorder_rset = shop_schema->resultset('PaymentOrder');

        lives_ok { $paymentorder_rset->delete_all }
        "delete existing payment orders";

        # test with various bad (or no) args

        lives_ok { $mech->post('/shop_charge') }
        'shop_charge with no args dies';

        cmp_ok $mech->status, 'eq', '500', 'status is 500';

        lives_ok {
            $mech->post( '/shop_charge', { provider => "BadProvider" } )
        }
        'shop_charge with bad provider dies';

        cmp_ok $mech->status, 'eq', '500', 'status is 500';

        like $mech->content, qr/Settings for provider BadProvider missing/,
        "error contains Settings for provider BadProvider missing";

        $mech->post_ok(
            '/shop_charge',
            { amount => 1 },
            "shop_charge { amount => 1 }"
        );
        
        $mech->content_like(
            qr/1,\d+,\d+,Interchange6::Schema::Result::PaymentOrder,1,success/,
            "charge and payment order are good" );

        cmp_ok $paymentorder_rset->count, '==', 1, "1 payment order in db";

        $mech->post_ok(
            '/shop_charge',
            { amount => 1, provider => 'MockSuccess' },
            "shop_charge { amount => 1, provider => 'MockSuccess' }"
        );
        
        $mech->content_like(
            qr/1,\d+,\d+,Interchange6::Schema::Result::PaymentOrder,1,success/,
            "charge and payment order are good" );

        cmp_ok $paymentorder_rset->count, '==', 2, "2 payment orders in db";

        $mech->post_ok(
            '/shop_charge',
            { amount => 1, provider => 'MockFail' },
            "shop_charge { amount => 1, provider => 'MockFail' }"
        );
        
        $mech->content_like(
            qr/0,,,Interchange6::Schema::Result::PaymentOrder,1,failure/,
            "charge and payment order are good" );

        cmp_ok $paymentorder_rset->count, '==', 3, "3 payment orders in db";

        lives_ok {
            $mech->post( '/shop_charge',
                { amount => 1, provider => 'MockDie' } )
        }
        "shop_charge { amount => 1, provider => 'MockDie' }";
        
        $mech->content_like( qr/Payment with provider MockDie failed/,
            "error looks good" );

        cmp_ok $paymentorder_rset->count, '==', 4, "4 payment orders in db";

    };

    subtest 'shop_address' => sub {

        my $result;

        lives_ok { $result = shop_address } "shop_address lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        cmp_ok $result->count, '>', 0, "we have some addresses";

        lives_ok {
            $result =
              shop_address->search( undef, { rows => 1 } )->next
        }
        "get a random address";

        isa_ok $result, "Interchange6::Schema::Result::Address", "address";

        lives_ok { $result = shop_address( $result->id ) }
        "shop_address find lives";

        isa_ok $result, "Interchange6::Schema::Result::Address", "address";
    };

    subtest 'shop_attribute' => sub {

        my $result;

        lives_ok { $result = shop_attribute } "shop_attribute lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        cmp_ok $result->count, '>', 0, "we have some attributes";

        lives_ok {
            $result = shop_attribute->search( undef, { rows => 1 } )->next
        }
        "get a random attribute";

        isa_ok $result, "Interchange6::Schema::Result::Attribute", "attribute";

        lives_ok { $result = shop_attribute( $result->id ) }
        "shop_attribute find lives";

        isa_ok $result, "Interchange6::Schema::Result::Attribute", "attribute";
    };

    subtest 'shop_country' => sub {

        my $result;

        lives_ok { $result = shop_country } "shop_country lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        lives_ok { $result = shop_country("MT") } "find country MT";

        isa_ok $result, "Interchange6::Schema::Result::Country", "MT";
    };

    subtest 'shop_message' => sub {

        my $result;

        lives_ok { $result = shop_message } "shop_message lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        cmp_ok $result->count, '>', 0, "we have some messages";

        lives_ok {
            $result =
              shop_message->search( undef, { rows => 1 } )->next
        }
        "get a random message";

        isa_ok $result, "Interchange6::Schema::Result::Message", "message";

        lives_ok { $result = shop_message( $result->id ) }
        "shop_message find lives";

        isa_ok $result, "Interchange6::Schema::Result::Message", "message";
    };

    subtest 'shop_navigation' => sub {

        my $result;

        lives_ok { $result = shop_navigation } "shop_navigation lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        lives_ok { $result = shop_navigation( { uri => 'hand-tools' } ) }
        "find navigation hand-tools";

        isa_ok $result, "Interchange6::Schema::Result::Navigation",
          "hand-tools";
    };

    subtest 'shop_order' => sub {

        my $result;

        lives_ok { $result = shop_order } "shop_order lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        cmp_ok $result->count, '>', 0, "we have some orders";

        lives_ok { $result = shop_order->search( undef, { rows => 1 } )->next }
        "get a random order";

        isa_ok $result, "Interchange6::Schema::Result::Order", "order";

        lives_ok { $result = shop_order( $result->id ) }
        "shop_order find lives";

        isa_ok $result, "Interchange6::Schema::Result::Order", "order";
    };

    subtest 'shop_product' => sub {

        my $result;

        lives_ok { $result = shop_product } "shop_product lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        lives_ok { $result = shop_product("os28004") } "find product os28004";

        isa_ok $result, "Interchange6::Schema::Result::Product", "os28004";
    };

    subtest 'shop_state' => sub {

        my $state;

        lives_ok { shop_state } "shop_state lives";

        lives_ok {
            $state =
              shop_state( { country_iso_code => 'US', state_iso_code => 'CA' } )
        }
        "find state CA in US";

        isa_ok $state, "Interchange6::Schema::Result::State", "CA/US";
    };

    subtest 'shop_user' => sub {

        my $result;

        lives_ok { $result = shop_user } "shop_user lives";

        like ref($result), qr/ResultSet/, "returns a ResultSet";

        lives_ok { $result = shop_user( { username => "customer1" } ) }
        "find user customer1";

        isa_ok $result, "Interchange6::Schema::Result::User", "customer1";
    };

}
1;
