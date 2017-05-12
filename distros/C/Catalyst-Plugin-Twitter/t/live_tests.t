use strict;
use warnings;

use lib qw( lib t );

use Test::More;
use Test::WWW::Mechanize::Catalyst 'TestApp';

plan $ENV{TEST_TWITTER_DETAILS}
    ? ( tests => 6 )
    : ( skip_all => 'need "$user:$pass" in $ENV{TEST_TWITTER_DETAILS}' );

my $localhost        = 'http://localhost';
my $twitter_username = TestApp->config->{twitter}{username};
my $twitter_page     = "http://www.twitter.com/$twitter_username";

my $mech = Test::WWW::Mechanize::Catalyst->new();
$mech->allow_external(1);

# create a test string to test with
my $test_string
    = "Testing Catalyst::Plugin::Twitter v$Catalyst::Plugin::Twitter::VERSION: "
    . int rand 1_000_000_000;

# check that the string is not on the twitter page
$mech->get_ok($twitter_page);
$mech->content_lacks($test_string);

# send a test tweet
$mech->post_ok( "$localhost/tweet", { status => $test_string } );

# pause
pass "sleep to give twitter a chance to update";
sleep 5;

# check that the string is on the twitter page
$mech->get_ok($twitter_page);
$mech->content_contains($test_string);
