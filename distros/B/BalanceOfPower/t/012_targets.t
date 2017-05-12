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
my $commands = $world->build_commands();
$commands->set_player("Tester");
my $target = BalanceOfPower::Targets::Fall->new(target_obj => $world->get_nation("Italy"), 
                                                government_id => $world->get_nation("Italy")->government_id, 
                                                countdown => 16);
$world->get_player("Tester")->add_target($target);

$world->forced_advisor("Noone");
$world->get_nation("Italy")->internal_disorder(10);
$world->get_nation("Italy")->army(2);
is($world->get_nation("Italy")->government_id, 0, "Italy has government 0");
is($world->get_player("Tester")->mission_points, 0, "Player has no mission points");
$world->pre_decisions_elaborations("1970/1");
$world->get_nation("Italy")->add_internal_disorder(70, $world);
$world->post_decisions_elaborations();
$world->elaborate_turn("1970/2");
$world->elaborate_turn("1970/3");
$world->elaborate_turn("1970/4");
$world->elaborate_turn("1971/1");
$world->elaborate_turn("1971/2");
is($world->get_nation("Italy")->government_id, 1, "Italy has government 1");
is($world->get_player("Tester")->mission_points, 1, "Player gained a mission point");

done_testing();
