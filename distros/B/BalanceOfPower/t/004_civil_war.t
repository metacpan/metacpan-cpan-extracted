use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );

$world->tricks( { "Starting production0 Italy" => [10],
                  "Starting production1 Italy" => [10],
                  "Starting production2 Italy" => [10],
                  "Starting production3 Italy" => [10],
                  "Internal disorder random factor for Italy" => [1],
                  "Civil war in Italy: government fight result" => [ (55) x 6 ],
                  "Civil war in Italy: rebels fight result" => [ (60) x 6 ],
              });  
$world->init_random("nations-test-single.txt", "borders-test-single.txt", 
                    { alliances => 0,
                      trades => 0 });

$world->forced_advisor("Noone");
$world->get_nation("Italy")->internal_disorder(10);
$world->get_nation("Italy")->army(2);
is($world->get_nation("Italy")->government_id, 0, "Italy has government 0");
$world->pre_decisions_elaborations("1970/1");
$world->get_nation("Italy")->add_internal_disorder(70, $world);
$world->post_decisions_elaborations();
is($world->get_events("CIVIL WAR OUTBREAK IN Italy", "1970/1"), 1, "Civil war in Italy starts");
is($world->get_civil_war("Italy")->rebel_provinces(), 1.5, "Government wins first battle with army help");
is($world->get_nation("Italy")->army(), 0, "Army decreased for civil war");
$world->elaborate_turn("1970/2");
$world->elaborate_turn("1970/3");
$world->elaborate_turn("1970/4");
$world->elaborate_turn("1971/1");
$world->elaborate_turn("1971/2");
is($world->get_events("THE REBELS IN Italy WON THE CIVIL WAR", "1971/2"), 1, "Rebels won the civil war");
is($world->get_nation("Italy")->government_id, 1, "Italy has government 1");

done_testing();
