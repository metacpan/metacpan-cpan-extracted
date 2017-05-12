use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'disabled_cart_and_checkout';
}

use Test::More import => ['!pass'];
use Test::Exception;
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';
use TestApp;

use Dancer2;
use Dancer2::Plugin::DBIC;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $mech = Test::WWW::Mechanize::PSGI->new( app => TestApp->to_app );

my ( $schema, $fixtures );

subtest "deploy and install fixtures" => sub {

    lives_ok { $schema = schema } "Connect to schema";

    lives_ok { $schema->deploy } "Deploy schema";

    lives_ok { $fixtures = Fixtures->new( ic6s_schema => $schema ) }
    "get fixtures";

    lives_ok { $fixtures->navigation } "deploy navigation fixtures";
};

subtest "cart route not defined" => sub {

    $mech->get('/cart');

    ok $mech->status eq '404', "/cart not found" or diag $mech->status;
};

subtest "checkout route not defined" => sub {

    $mech->get('/checkout');

    ok $mech->status eq '404', "/checkout not found" or diag $mech->status;
};

subtest "navigation with undef records" => sub {

    $mech->get('/hand-tools');

    ok $mech->status eq '500', "/hand-tools crashed" or diag $mech->status;
};

done_testing;
