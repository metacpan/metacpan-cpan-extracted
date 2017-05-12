package Test::Shop;

use strict;
use warnings;

use Test::Exception;
use Test::More;
use Dancer2 '!pass', appname => 'TestApp';
use Dancer2::Plugin::Interchange6;

sub run_tests {

    diag "Test::Shop";

    my $ret;

    my $shop_schema = shop_schema;

    # check PL country
    $ret = shop_country->find('PL');

    isa_ok($ret, 'Interchange6::Schema::Result::Country');
    ok($ret->name eq 'Poland', 'Country name Poland');
    ok($ret->show_states == 0, 'Show states for Poland');

    # check US country
    $ret = shop_country->find('US');

    isa_ok($ret, 'Interchange6::Schema::Result::Country');
    ok($ret->name eq 'United States', 'Country name United States');
    ok($ret->show_states == 1, 'Show states for United States');

    # check Manitoba
    $ret = shop_state->find({state_iso_code => 'MB'});

    isa_ok($ret, 'Interchange6::Schema::Result::State');
    ok($ret->country_iso_code eq 'CA', 'Country code for Canada');

    # create product
    my %product_data;

    %product_data = (
        sku => 'F0001',
        name => 'One Dozen Roses',
        short_description => 'What says I love you better than 1 dozen fresh roses?',
        description => 'Surprise the one who makes you smile, or express yourself perfectly with this stunning bouquet of one dozen fresh red roses. This elegant arrangement is a truly thoughtful gift that shows how much you care.',
        price => '39.95',
        uri => 'one-dozen-roses',
        weight => '4',
    );

    my $product = shop_product->create(\%product_data);
    isa_ok($product, 'Interchange6::Schema::Result::Product');

    # create review
    my %review_data;

    %review_data = (
        author_users_id => shop_user->first->id,
        title => 'test',
        content => 'Text review',
        rating => 2,
    );

    my $message_count = shop_message->count;

    lives_ok( sub { $ret = $product->set_reviews(\%review_data) },
    "add a product review" );

    $message_count++;

    cmp_ok( shop_message->count, '==', $message_count,
        "$message_count Message rows" );
}

1;
