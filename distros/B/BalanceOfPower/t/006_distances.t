use lib "lib";
use BalanceOfPower::World;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random('nations-test1.txt', 'borders-test1.txt', { alliances => 0, trades => 0, diplomacy => 1 });
is($world->distance("Italy", "France"), 1, "Italy - France: 1");
is($world->distance("Italy", "United Kingdom"), 2, "Italy - United Kingdom: 2");
is($world->distance("France", "United Kingdom"), 2, "France - United Kingdom: 2");
is($world->distance("Germany", "United Kingdom"), 1, "Germany - United Kingdom: 1");
is($world->near_nations("Italy"), 2, "Italy has two nations in military range");
$world->get_nation("Italy")->army(15);
$world->diplomacy_exists("Italy", "Germany")->factor(90);
$world->start_military_support($world->get_nation("Italy"), $world->get_nation("Germany"));
is($world->near_nations("Italy"), 3, "Through support, Italy has tre nations in military range");
is($world->near_nations("Italy", 1), 2, "Nations on borders are still 2");



done_testing();

