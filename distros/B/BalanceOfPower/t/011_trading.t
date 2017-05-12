use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;
use Data::Dumper;

my $first_year = 1970;


#Scenario: a neighbor has military support from an enemy nation
my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->autopilot($first_year, $first_year);
my $commands = $world->build_commands();
$commands->set_player("Tester");
$world->get_nation("Italy")->internal_disorder(0);
$world->statistics->{'1970/3'}->{'Italy'}->{'w/d'} = 40;
$commands->query("buy 3 Italy");
$commands->stock_commands();
$world->decisions();
$world->post_decisions_elaborations();
$world->pre_decisions_elaborations();
my $player = $world->get_player("Tester");
is($player->money, 880, "Money correctly subtracted"); 
is($player->stocks("Italy"), 3, "3 Italy stocks owned by player"); 
is($player->influence("Italy"), 1.5, "Influence on Italy is 1.5"); 
$world->statistics->{'1970/4'}->{'Italy'}->{'w/d'} = 50;
$world->get_nation("Italy")->internal_disorder(0);
$world->get_nation("Germany")->internal_disorder(90);
$commands->query("sell 2 Italy");
$commands->stock_commands();
$world->decisions();
$world->post_decisions_elaborations();
$world->pre_decisions_elaborations();
is($player->money, 980, "Money correctly gained"); 
is($player->stocks("Italy"), 1, "1 Italy stocks owned by player"); 
$commands->query("buy 1 Germany");
$commands->commands();
is($commands->latest_result->{'status'}, -14, "You can't trade during civil war");  
$commands->query("control Italy");
$commands->commands();
$commands->query("PROGRESS");
$commands->commands();
$world->post_decisions_elaborations();
is($world->statistics->{'1971/2'}->{'Italy'}->{'order'}, "PROGRESS", "Italy did progress as ordered");
is($player->influence("Italy"), .5, "Influence on Italy is .5");
$world->pre_decisions_elaborations();
$world->get_nation("Italy")->army(10);
$world->get_nation("France")->army(10);
$world->set_diplomacy("Italy", "France", 3);
$world->ia_orders([ "Italy: DECLARE WAR TO France" ]);
$world->post_decisions_elaborations();
$world->pre_decisions_elaborations();
is($player->money, 930, "Payed for war bonds");
is($player->war_bonds("Italy"), 1, "1 war bond from Italy acquired");
$world->get_nation("France")->army(0);
$world->post_decisions_elaborations();
$world->pre_decisions_elaborations();
is($player->money, 1060, "Italy won the war. War bonds returned a gain of 180");
is($player->war_bonds("Italy"), 0, "War bonds erased");
done_testing();
  

