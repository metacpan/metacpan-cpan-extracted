#!perl
use warnings;
use strict;

use Test::More;
use Test::MockModule;
use Test::Bot::BasicBot::Pluggable;
use Test::MockObject::Extends;

my @test_users = (qw/test1 test2 test3/);

my $module = new Test::MockModule('Bot::BasicBot::Pluggable');
$module->mock('pocoirc', sub {
    my $mock_pocoirc = Test::MockObject->new();
    $mock_pocoirc->set_list( 'channel_list', @test_users );
    return $mock_pocoirc;
});

my $bot = Test::Bot::BasicBot::Pluggable->new();
$bot->load('Tea');

my $tea_response = $bot->tell_indirect('!tea');
$tea_response =~ /^test_user would like a brew! (.+): your turn!$/;
ok( $1 ~~ @test_users, "Returned a user ($1) from the list" );

my $user_just_called = $1;

# test that !tea status returns the expected users
my @tea_drinkers = _get_tea_drinkers();

# all the users on the list are the ones we're expecting
is_deeply( [sort @tea_drinkers], [sort @test_users], "Expected tea drinkers found - no crack here" );

# test user just called is at back of list
is( $tea_drinkers[-1], $user_just_called, "User just called is now at back of list");

# test that the list of users doesn't contain test_user (bot's name)
unlike( join(' ' , @tea_drinkers), qr/test_user/, "Didn't get the bot's name in the rota" );


# test the 'away' functionality - there be monsters here.
my $currently_next = $tea_drinkers[0];
my $away_response = $bot->tell_indirect('!tea away');

like( $away_response, qr/^test_user says $user_just_called is AWOL\. $currently_next, take over!$/, "AWOL user correctly called" );

# refresh list of tea drinkers and check order
@tea_drinkers = _get_tea_drinkers();
#1st place
is( $tea_drinkers[0], $user_just_called, "The AWOL user is back at the front of the queue");
#last place
is ($tea_drinkers[-1], $currently_next, "The user who was next is now at the back of queue");
#all
is_deeply( [sort @tea_drinkers], [sort @test_users], "Expected tea drinkers found - no crack here" );


# test the 'volunteer' functionality CAN'T TEST THIS - ALL THE COMMANDS WE ISSUE ARE AS THE BOT AND IT WON'T FEATURE IN THE ALL TEA DRINKERS ARRAY
# my $volunteer_response = $bot->tell_indirect('!tea volunteer');
# like( $volunteer_response, qr/^test_user has volunteered to make a round. test_user++$/, "AWOL user correctly called" );


done_testing();

sub _get_tea_drinkers {

    my $response = $bot->tell_indirect('!tea status');
    $response =~ /^Tea round status is\: (.*)$/;
    return split(',',$1);
}