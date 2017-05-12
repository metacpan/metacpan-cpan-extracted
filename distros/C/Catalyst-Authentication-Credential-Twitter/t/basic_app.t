
use strict;

use Test::More;
eval " use Test::WWW::Mechanize::Catalyst; 1 "
    or plan skip_all => 'test requires Test::WWW::Mechanize::Catalyst';

use lib 't/lib';

eval " use Test::MockObject; 1 "
    or plan skip_all => 'test requires Test::MockObject';

eval "use Catalyst::Plugin::Session::Store::FastMmap; 1"
    or plan skip_all => 'test requires Catalyst::Plugin::Session::Store::FastMmap';

my $twitter = Test::MockObject->new;
$twitter->fake_module( 'Net::Twitter' );
$twitter->fake_new( 'Net::Twitter' );
$twitter->set_always( get_authentication_url => 'http://twit/auth' );
$twitter->set_always( request_token => 'abc' );
$twitter->set_always( request_token_secret => 'hush' );
$twitter->set_always( request_access_token => 'request_access_token' );
$twitter->set_always( access_token => 'access_token' );
$twitter->set_always( access_token_secret => 'access_token_secret' );

my @users = (
{
    id => 'yanick',
    access_token => 'alpha',
    access_token_secret => 'beta',
},
{
    id => 'wilfred',
    access_token => 'delta',
    access_token_secret => 'gamma',
},
);

$twitter->mock( 'verify_credentials' => sub {
        return shift @users;
} );


# all used by TestApp
for my $plugin ( qw/
    Authentication
    Session
    Session::State::Cookie
    / ) {
    my $module = "Catalyst::Plugin::$plugin";
    eval "use $module; 1" or plan skip_all => "test requires $module";
}

# Create two separate mech objects to simulate two simultaneous sessions,
# to make sure that user authentication doesn't leak between them.
my $yanick_mech  = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');
my $wilfred_mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');

# Log in user 'yanick'.
$yanick_mech->get_ok('/index');
$yanick_mech->get_ok('/login');
$yanick_mech->content_contains( 'http://twit/auth' );
$yanick_mech->get_ok( '/auth?oauth_verifier=oauth' );
$yanick_mech->get_ok( '/authenticate' );
$yanick_mech->content_contains( 'yanick' );

# Log in user 'wilfred'.
$wilfred_mech->get_ok('/index');
$wilfred_mech->get_ok('/login');
$wilfred_mech->content_contains( 'http://twit/auth' );
$wilfred_mech->get_ok( '/auth?oauth_verifier=oauth' );
$wilfred_mech->get_ok( '/authenticate' );
$wilfred_mech->content_contains( 'wilfred' );

# Make sure that both users' sessions identify the logged-in user correctly.
$yanick_mech->get_ok( '/leaking_users' );
$yanick_mech->content_contains( 'yanick' );
$wilfred_mech->get_ok( '/leaking_users' );
$wilfred_mech->content_contains( 'wilfred' );

done_testing();

