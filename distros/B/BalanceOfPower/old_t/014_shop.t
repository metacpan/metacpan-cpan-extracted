use v5.10;
use lib "lib";
use BalanceOfPower::World;
use Test::More;

use Data::Dumper;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->tricks( { "Export quote Italy" => [50],
                  "Export quote France" => [50],
                  "Export quote Russia" => [50],
                  "Export quote Germany" => [50],
                  "Starting production0 Italy" => [30],
                  "Starting production1 Italy" => [30],
                  "Starting production2 Italy" => [30],
                  "Starting production3 Italy" => [30],
                  "Starting production0 France" => [10],
                  "Starting production1 France" => [10],
                  "Starting production2 France" => [10],
                  "Starting production3 France" => [10],
                  "Starting production0 Russia" => [20],
                  "Starting production1 Russia" => [20],
                  "Starting production2 Russia" => [20],
                  "Starting production3 Russia" => [20],
                  "Starting production0 Germany" => [30],
                  "Starting production1 Germany" => [30],
                  "Starting production2 Germany" => [30],
                  "Starting production3 Germany" => [30],
                  "Delta production Italy" => [(0) x 20],
                  "Delta production France" => [(0) x 20],
                  "Delta production Russia" => [(0) x 20],
                  "Delta production Germany" => [(0) x 20],
              });  

$world->init_random("nations-test2.txt", "borders-test2.txt", 
                    { alliances => 0,
                      trades => 0 });
$world->pre_decisions_elaborations("1970/1");

my $commands = $world->build_commands();
$commands->set_player("Tester");
$commands->get_active_player->position("Italy");

is($world->calculate_price("1970/1", 'goods', "Italy"), 10, "Price of goods in Italy is 10");
is($world->calculate_price("1970/1", 'goods', "France"), 23.33, "Price of goods in France is 23.33");
$commands->query("sbuy 10 goods");
$commands->commands();
is($commands->get_active_player->money, 900, "Money payed for goods");
is($commands->get_active_player->get_cargo("goods"), 10, "Goods in the hold");
$commands->get_active_player->movements(8);
$commands->query("go FRA");
$commands->commands();
$commands->query("ssell 5 goods");
$commands->commands();
is($commands->get_active_player->money, 1016.65, "Money earned for goods");
is($commands->get_active_player->get_cargo("goods"), 5, "Goods in the hold are 5");





done_testing();
